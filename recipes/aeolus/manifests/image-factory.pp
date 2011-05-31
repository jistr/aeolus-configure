# Aeolus image factory puppet definitions

class aeolus::image-factory inherits aeolus {

  package { 'libvirt':
            ensure=> 'installed'
  }
  package { 'imagefactory':
               ensure => 'installed',
               require => [Yumrepo['aeolus_arch', 'aeolus_noarch']]
  }
  package { 'qpid-cpp-server':
               ensure => 'installed' }

  ### Configure pulp to fetch from Fedora
    # TODO uncomment when factory/warehouse uses pulp
    #exec{"pulp_fedora_config":
    #      command => "/usr/bin/pulp-admin -u admin -p admin repo create --id=fedora-repo --feed yum:http://download.fedora.redhat.com/pub/fedora/linux/updates/13/x86_64/"
    #}

  ### Start the aeolus services
    file { "/etc/qpidd.conf":
               source => "puppet:///modules/aeolus/qpidd.conf",
               mode   => 644 }
    service {'qpidd':
               ensure  => 'running',
               enable  => true,
               require => [File['/etc/qpidd.conf'],
                           Package['qpid-cpp-server']]}
    file { "/var/tmp/imagefactory-mock":
               ensure => "directory",
               mode   => 755 }
    service {'libvirtd':
               ensure  => 'running',
               enable  => true,
               hasstatus => true,
               require => Package['libvirt']}
    $requires = [Package['imagefactory'],
                 File['/var/tmp/imagefactory-mock'],
                 Service[qpidd], Service[libvirtd],
                 Rails::Seed::Db[seed_aeolus_database]]
    service { 'imagefactory':
      ensure  => 'running',
      enable  => true,
      hasstatus => true,
      require => $requires}
}

class aeolus::image-factory::disabled {
  ### Stop the aeolus services
    service {'qpidd':
               ensure  => 'stopped',
               enable  => false,
               require => Service['imagefactory']}

    service { 'imagefactory':
      ensure  => 'stopped',
      hasstatus => true,
      enable  => false}

  ### Destroy and cleanup aeolus artifacts
    exec{"remove_aeolus_templates":     command => "/bin/rm -rf /templates"}
}
