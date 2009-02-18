
Summary: Hosttag client
Name: hosttag
Version: 0.1
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

%prep
%setup

%build

%install
test "%{buildroot}" != "/" && rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
install bin/hosttag %{buildroot}%{_bindir}
cd %{buildroot}%{_bindir}
ln -s hosttag ht

%clean
test "%{buildroot}" != "/" && rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{_bindir}/*

%changelog
* Thu Feb 19 2009 Gavin Carr <gavin@openfusion.com.au> 0.1
- Initial package, version 0.1.

