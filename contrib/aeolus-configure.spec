%define dchome /usr/share/aeolus-configure
%define pbuild %{_builddir}/%{name}-%{version}

Summary:  Aeolus Configure Puppet Recipe
Name:     aeolus-configure
Version:  2.0.1
Release:  0%{?dist}%{?extra_release}

Group:    Applications/Internet
License:  GPLv2+
URL:      http://aeolusproject.org
Source0:  %{name}-%{version}.tgz
BuildRoot:  %{_tmppath}/%{name}-%{version}
BuildArch:  noarch
Requires:   puppet
Requires:   rubygem(uuidtools)
# To send a request to iwhd rest interface to
# create buckets, eventually replace w/ an
# iwhd client
Requires:  curl
Requires:  rubygem-curb

%description
Aeolus Configure Puppet Recipe

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
%{__mkdir} -p %{buildroot}/%{dchome}/modules/aeolus %{buildroot}/%{_sbindir}
%{__mkdir} -p %{buildroot}%{_sysconfdir}/aeolus-configure/nodes
%{__cp} -R %{pbuild}/conf/* %{buildroot}%{_sysconfdir}/aeolus-configure/nodes
%{__cp} -R %{pbuild}/recipes/aeolus/*/ %{buildroot}/%{dchome}/modules/aeolus
%{__cp} -R %{pbuild}/recipes/apache/ %{buildroot}/%{dchome}/modules/apache
%{__cp} -R %{pbuild}/recipes/ntp/ %{buildroot}/%{dchome}/modules/ntp
%{__cp} -R %{pbuild}/recipes/openssl/ %{buildroot}/%{dchome}/modules/openssl
%{__cp} -R %{pbuild}/recipes/postgres/ %{buildroot}/%{dchome}/modules/postgres
%{__cp} -R %{pbuild}/bin/aeolus-configure %{buildroot}/%{_sbindir}/
%{__cp} -R %{pbuild}/bin/aeolus-cleanup %{buildroot}/%{_sbindir}/
%{__cp} -R %{pbuild}/bin/aeolus-node %{buildroot}/%{_sbindir}/\

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0755, root, root) %{_sbindir}/aeolus-configure
%attr(0755, root, root) %{_sbindir}/aeolus-cleanup
%attr(0755, root, root) %{_sbindir}/aeolus-node
%config(noreplace) %{_sysconfdir}/aeolus-configure/nodes/*
%{dchome}

%changelog
* Wed May 18 2011 Mike Orazi <morazi@redhat.com> 2.0.1-0
- Move using external nodes so changes to behavior can happen in etc

* Wed May 18 2011 Chris Lalancette <clalance@redhat.com> - 2.0.0-11
- Bump the release version

* Tue Mar 22 2011 Angus Thomas <athomas@redhat.com> 2.0.0-5
- Removed iwhd init script and config file

* Wed Feb 17 2011 Mohammed Morsi <mmorsi@redhat.com> 2.0.0-3
- renamed deltacloud-configure to aeolus-configure

* Tue Feb 15 2011 Mohammed Morsi <mmorsi@redhat.com> 2.0.0-3
- various fixes to recipe

* Thu Jan 14 2011 Mohammed Morsi <mmorsi@redhat.com> 2.0.0-2
- include openssl module


* Mon Jan 10 2011 Mike Orazi <morazi@redhat.com> 2.0.0-1
- Make this a drop in replacement for the old deltacloud-configure scripts

* Wed Dec 22 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.4-1
- Revamp deltacloud recipe to make it more puppetized,
  use general purpose firewall, postgres, ntp modules,
  and to fix many various things

* Wed Sep 29 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.3-1
- Renamed package from deltacloud appliance
- to deltacloud recipe

* Wed Sep 29 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.2-3
- Include curl-devel for typhoeus gem

* Wed Sep 29 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.2-2
- Updated to pull in latest git changes

* Fri Sep 17 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.2-1
- Updated packages pulled in to latest versions
- Various fixes
- Added initial image warehouse bits

* Thu Sep 02 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.1-1
- Initial package

