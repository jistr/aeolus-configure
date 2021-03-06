#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

class apache {
	# require apache and mod_ssl
	package { "httpd":
                    ensure => installed,
                    source => $package_provider }

  if $enable_https {
	  package { "mod_ssl":
                      ensure => installed,
                      source => $package_provider }

      if $enable_kerberos {
             package { "mod_auth_kerb":
                          ensure => installed,
                          source => $package_provider }
      }

   }

  # if selinux is enabled and we want to use mod_proxy, we need todo this
  exec{'permit-http-networking':
         command => '/usr/sbin/setsebool -P httpd_can_network_connect 1',
         logoutput => true,
         unless   => "/usr/bin/test 'Disabled' = `/usr/sbin/getenforce` ||
                      (/usr/sbin/getsebool httpd_can_network_connect | grep -q 'on$')"
  }

	service { "httpd":
		ensure     => running,
		require    => [Package["httpd"], Exec['permit-http-networking']],
		hasrestart => true,
    hasstatus  => true,
    enable     => true
	}

        # add a sleep here because httpd may have not finished starting up
	exec { "reload-apache":
          command     => "/bin/sleep 1; /sbin/service httpd reload",
	  refreshonly => true,
  }
}


