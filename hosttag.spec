
Summary: Hosttag client
Name: hosttag
Version: 0.6.6
Release: 1%{org_tag}%{dist}
URL: http://www.openfusion.com.au/labs/
Source0: http://www.openfusion.com.au/labs/dist/%{name}-%{version}.tar.gz
License: GPL
Group: Applications/System
BuildRoot: %{_tmppath}/%{name}-%{version}
BuildArch: noarch
Requires: rubygems, rubygem-redis

%description
Hosttag is a client/server system for tagging hosts into groups or classes.
This package contains the hosttag client.

%package server
Summary: Hosttag server
Group: Applications/System
Requires: redis, rubygems, rubygem-redis

%description server
Hosttag is a client/server system for tagging hosts into groups or classes.
This package contains the hosttag server.

%prep
%setup

%build

%install
test "%{buildroot}" != "/" && rm -rf %{buildroot}

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_sbindir}
install -m0755 bin/hosttag %{buildroot}%{_bindir}/hosttag
install -m0755 bin/htexport %{buildroot}%{_bindir}/htexport

# htset and htimport are executable by root only, to restrict tagging to root
install -m0700 bin/htset %{buildroot}%{_sbindir}/htset
install -m0700 bin/htimport %{buildroot}%{_sbindir}/htimport

mkdir -p %{buildroot}%{_sysconfdir}/%{name}
install -m0644 etc/Makefile %{buildroot}%{_sysconfdir}/%{name}
install -m0644 etc/README %{buildroot}%{_sysconfdir}/%{name}

cd %{buildroot}%{_bindir}
ln -s hosttag ht

%clean
test "%{buildroot}" != "/" && rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{_bindir}/hosttag
%{_bindir}/ht
%attr(0700,root,root) %{_sbindir}/htset
%doc README LICENCE

%files server
%defattr(-,root,root)
%config(noreplace) %{_sysconfdir}/%{name}/Makefile
%{_sysconfdir}/%{name}/README
%attr(0755,root,root) %{_bindir}/htexport
%attr(0700,root,root) %{_sbindir}/htimport

%changelog
* Thu Dec 31 2009 Gavin Carr <gavin@openfusion.com.au> 0.6.6
- Rename hosttag_export to htexport, and hosttag_load_data to htimport.
- Change old --import parameter to htimport to --delete, like htexport.
- Make htimport more verbose, like htexport.

* Tue Dec 29 2009 Gavin Carr <gavin@openfusion.com.au> 0.6.5
- Add hosttag_export utility to export redis db back to directory tree.

* Tue Dec 08 2009 Gavin Carr <gavin@openfusion.com.au> 0.6
- Move from tokyo cabinet/tyrant server to redis-based one.
- Rewrite client in ruby.

* Wed Nov 04 2009 Gavin Carr <gavin@openfusion.com.au> 0.5
- Fixes to hosttag_load_data.
- Add SKIP tag support to hosttag_load_data.
- Mode fixes to hosttag.
- Add htserver init scripts to hosttag-server package.

* Thu Oct 01 2009 Gavin Carr <gavin@openfusion.com.au> 0.4
- Rename data to etc, and load_data to hosttag_load_data.
- Add -server subpackage to hosttag.spec.

* Thu Oct 01 2009 Gavin Carr <gavin@openfusion.com.au> 0.3
- Change -h|--hosts parameters to -t|--tags (and deprecate -h).
- Allow bare 'ht -t' for listing all tags.
- Add default rel for multitag and multihost queries.

* Thu Feb 19 2009 Gavin Carr <gavin@openfusion.com.au> 0.1
- Initial package, version 0.1.

