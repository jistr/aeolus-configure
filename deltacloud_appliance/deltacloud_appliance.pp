#--
#  Copyright (C) 2010 Red Hat Inc.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
# Author: Mohammed Morsi <mmorsi@redhat.com>
#--

#
# deltacloud thincrust appliance
#

# Modules used by the appliance
import "appliance_base"
import "banners"
import "firewall"
#import "console"

# Information about our appliance
$appliance_name = "Deltacloud Appliance"
$appliance_version = "0.0.1"

# Configuration
appliance_base::setup{$appliance_name:}
appliance_base::enable_updates{$appliance_name:}
banners::all{$appliance_name:}
firewall::setup{$appliance_name: status=>"enabled"}

# Install required gems
single_exec{"install_required_gems":
            command => "/usr/bin/gem install authlogic gnuplot scruffy compass builder"
}

# TODO setup a gem repo w/ latest snapshots of image builder, deltacloud core if we need those

# Deltacloud core
single_exec{"install_deltacloud_core":
            command => "/usr/bin/gem install deltacloud-client deltacloud-core"
}

# Image builder

# FIXME when image builder is pushed to rubygems and/or rpm is available
# install via that means and remove this wget
single_exec{"download_image_builder":
            command => "/usr/bin/wget http://projects.morsi.org/deltacloud/deltacloud-image-builder-agent-0.0.1.gem http://projects.morsi.org/deltacloud/deltacloud-image-builder-console-0.0.1.gem"
}
single_exec{"install_image_builder":
            command => "/usr/bin/gem install deltacloud-image-builder-agent-0.0.1.gem deltacloud-image-builder-console-0.0.1.gem",
            require => Single_exec[download_image_builder]
}

# Pulp
# Configure pulp to fetch from Fedora
# FIXME currently major blocker with puppet / pulp:
#   1) ace's single_exec invokes puppet's execute (lib/puppet/util.rb)
#   2) puppet execute sets locale environment variables to posix default ('C') immediately before running the command (lib/puppet/util.rb line 295)
#   3) pulp-admin attempts to attain default locale (pulp/client/connection.py line 80)
#   4) the python locale module attempts to parse these locale env vars (/usr/lib64/python2.6/locale.py line 471)
#   5) setting those vars to 'C' causes the locale module to return None (locale.py line 409) which causes pulp-admin to thow a fatal exception
#
# There is no way to get around this here, since puppet sets the locale env vars and then immediately invokes Kernel.exec('pulp-admin...').
# We can move the pulp-admin command to the kickstart or deltacloud_appliance rpm spec for a quick workaround for the time being, though
# a bug should really be filed against either puppet or pulp.
#single_exec{"pulp_fedora_config":
#            command => "/usr/bin/pulp-admin -u admin -p admin repo create --id=fedora-repo --feed yum:http://download.fedora.redhat.com/pub/fedora/linux/updates/13/x86_64/"
#}

# Configure and start condor-dcloud
file {"/var/lib/condor/condor_config.local":
       source => "puppet:///deltacloud_appliance/condor_config.local",
       notify          => Service[condor]
}
service {"condor" :
       ensure => running,
       enable => true
}

# Configure and start postgres
single_exec {"initialize_db":
      command => "/sbin/service postgresql initdb"
}
file {"/var/lib/pgsql/data/pg_hba.conf":
       source => "puppet:///deltacloud_appliance/pg_hba.conf",
       require => Single_exec[initialize_db]
}
service {"postgresql" :
       ensure => running,
       enable => true,
       require => File["/var/lib/pgsql/data/pg_hba.conf"]
}
# XXX ugly hack, postgres takes sometime to startup even though reporting as running
# need to pause for a bit to ensure it is running before we try to access the db
single_exec{"postgresql_startup_pause":
            command => "/bin/sleep 5",
            require => Service[postgresql]
}
single_exec{"create_dcloud_postgres_user":
            command => "/usr/bin/psql postgres postgres -c \"CREATE USER dcloud WITH PASSWORD 'v23zj59an' CREATEDB\"",
            require => Single_exec[postgresql_startup_pause]
}

# Create deltacloud database
single_exec{"create_deltacloud_database":
            cwd     => "/usr/share/deltacloud-aggregator",
            environment     => "RAILS_ENV=production",
            command         => "/usr/bin/rake db:create:all",
            require => [Single_exec[create_dcloud_postgres_user], Single_exec[install_required_gems], Single_exec[install_deltacloud_core]]
}
single_exec{"migrate_deltacloud_database":
            cwd             => "/usr/share/deltacloud-aggregator",
            environment     => "RAILS_ENV=production",
            command => "/usr/bin/rake db:migrate",
            require => Single_exec[create_deltacloud_database]
}

# install init.d control script for deltacloudd
file {"/etc/init.d/deltacloud-core":
      source => "puppet:///deltacloud_appliance/deltacloud-core",
      mode   => 755
}

# Startup Deltacloud services
service {"deltacloud-aggregator" :
       ensure => running,
       enable => true,
       require => [Single_exec[install_required_gems], Single_exec[migrate_deltacloud_database]]
}
service{"deltacloud-core":
       ensure => running,
       enable => true,
       require => [Single_exec[install_deltacloud_core], File["/etc/init.d/deltacloud-core"]]
}
