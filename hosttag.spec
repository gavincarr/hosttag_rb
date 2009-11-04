
Summary: Hosttag client
Name: hosttag
Version: 0.5
Release: 1%{org_tag}%{dist}
URL: http://www.openfusion.com.au/labs/
Source0: http://www.openfusion.com.au/labs/dist/%{name}-%{version}.tar.gz
License: GPL
Group: Applications/System
BuildRoot: %{_tmppath}/%{name}-%{version}
BuildArch: noarch

%description
Hosttag is a client/server system for tagging hosts into groups or classes.
This package contains the hosttag client.

%package server
Summary: Hosttag server
Group: Applications/System
Requires: tokyocabinet, tokyotyrant

%description server
Hosttag is a client/server system for tagging hosts into groups or classes.
This package contains the hosttag server.

%prep
%setup

%build

%install
test "%{buildroot}" != "/" && rm -rf %{buildroot}

mkdir -p %{buildroot}%{_bindir}
install -m0755 bin/hosttag %{buildroot}%{_bindir}
install -m0755 bin/hosttag_load_data %{buildroot}%{_bindir}

mkdir -p %{buildroot}%{_sysconfdir}/%{name}
mkdir -p %{buildroot}%{_sysconfdir}/rc.d/init.d
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig
install -m0644 etc/Makefile %{buildroot}%{_sysconfdir}/%{name}
install -m0644 etc/README %{buildroot}%{_sysconfdir}/%{name}
install -m0755 etc/htserver/htserver.init %{buildroot}%{_sysconfdir}/rc.d/init.d/htserver
install -m0755 etc/htserver/htserver.sysconfig %{buildroot}%{_sysconfdir}/sysconfig/htserver

cd %{buildroot}%{_bindir}
ln -s hosttag ht

%clean
test "%{buildroot}" != "/" && rm -rf %{buildroot}

%post 
/sbin/chkconfig --add htserver

%files
%defattr(-,root,root)
%{_bindir}/hosttag
%{_bindir}/ht
%doc README LICENCE

%files server
%defattr(-,root,root)
%config(noreplace) %{_sysconfdir}/%{name}/Makefile
%{_sysconfdir}/%{name}/README
%{_bindir}/hosttag_load_data
%{_sysconfdir}/rc.d/init.d/htserver
%config(noreplace) %{_sysconfdir}/sysconfig/htserver

%changelog
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

