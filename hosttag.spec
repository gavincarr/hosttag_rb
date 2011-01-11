%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")

Summary: Hosttag client
Name: hosttag
Version: 0.10.2
Release: 1%{org_tag}%{dist}
URL: http://www.openfusion.com.au/labs/
Source0: http://www.openfusion.com.au/labs/dist/%{name}-%{version}.tar.gz
License: GPL
Group: Applications/System
BuildRoot: %{_tmppath}/%{name}-%{version}
BuildArch: noarch
Requires: rubygems, rubygem-redis >= 2.0.0

%description
Hosttag is a client/server system for tagging hosts into groups or classes.
This package contains the hosttag client.

%package server
Summary: Hosttag server
Group: Applications/System
Requires: hosttag = %version
Requires: redis, rubygems, rubygem-redis

%description server
Hosttag is a client/server system for tagging hosts into groups or classes.
This package contains the hosttag server.

%prep
%setup

%build

%install
test "%{buildroot}" != "/" && rm -rf %{buildroot}

mkdir -p %{buildroot}%{ruby_sitelib}/hosttag
install -m0644 lib/hosttag.rb %{buildroot}%{ruby_sitelib}/hosttag.rb
install -m0644 lib/hosttag/server.rb %{buildroot}%{ruby_sitelib}/hosttag

mkdir -p %{buildroot}%{_bindir}
install -m0755 bin/hosttag %{buildroot}%{_bindir}/hosttag
install -m0755 bin/htexport %{buildroot}%{_bindir}/htexport

# htset and htimport are executable by root only, to restrict tagging to root
install -m0700 bin/htset %{buildroot}%{_bindir}/htset
install -m0700 bin/htdump %{buildroot}%{_bindir}/htdump
install -m0700 bin/htimport %{buildroot}%{_bindir}/htimport

mkdir -p %{buildroot}%{_sysconfdir}/%{name}
install -m0644 etc/Makefile %{buildroot}%{_sysconfdir}/%{name}
install -m0644 etc/README %{buildroot}%{_sysconfdir}/%{name}

cd %{buildroot}%{_bindir}
ln -s hosttag ht
cd %{buildroot}%{_bindir}
ln -s htset htdel

%clean
test "%{buildroot}" != "/" && rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{ruby_sitelib}/hosttag.rb
%{ruby_sitelib}/hosttag/*
%{_bindir}/hosttag
%{_bindir}/ht
%attr(0700,root,root) %{_bindir}/htset
%attr(0700,root,root) %{_bindir}/htdump
%{_bindir}/htdel
%doc README LICENCE

%files server
%defattr(-,root,root)
%config(noreplace) %{_sysconfdir}/%{name}/Makefile
%{_sysconfdir}/%{name}/README
%attr(0755,root,root) %{_bindir}/htexport
%attr(0700,root,root) %{_bindir}/htimport

%changelog
* Thu Jan 11 2011 Gavin Carr <gavin@openfusion.com.au> 0.10.2
- Fix some buglets in htset.
- Move root utils from %{_sbindir} to %{_bindir}.

* Fri Jan 07 2011 Gavin Carr <gavin@openfusion.com.au> 0.10.1
- Fix a couple of small bugs in 0.10.

* Thu Jan 06 2011 Gavin Carr <gavin@openfusion.com.au> 0.10
- Librification release, creating new Hosttag module with core functionality.
- Rewrite hosttag, htset, and htimport to use new Hosttag module.
- Rewrite hosttag_{add,delete}_tags routines to handle tricksy SKIP corner cases.
- Create lib versions of unit tests alongside existing bin ones.
- Expand unit test coverage for htset/htdel.
- Update unit tests to use library calls instead of calling out to utils.
- Change all_{hosts,tags}_* key names for greater clarity.

* Mon May 24 2010 Gavin Carr <gavin@openfusion.com.au> 0.9
- Migrate redis api calls over to redis 2.0.0 gem.
- Add --all option to htdel, for deleting all tags from a host.
- Add --host and --tag option to htset for ambiguous elements.

* Fri Feb 12 2010 Gavin Carr <gavin@openfusion.com.au> 0.8.1
- Add a -1 argument to hosttag to list results one per line.

* Mon Feb 08 2010 Gavin Carr <gavin@openfusion.com.au> 0.8
- Refactor, pulling server bits into Hosttag::Server.
- Add htset unit test, and fix bugs arising.

* Mon Feb 08 2010 Gavin Carr <gavin@openfusion.com.au> 0.7.1
- Fix typo in htset.

* Fri Feb 05 2010 Gavin Carr <gavin@openfusion.com.au> 0.7
- Add namespace option to all binaries.
- Add options to htdump.
- Add missing htdump to spec file.

* Wed Feb 03 2010 Gavin Carr <gavin@openfusion.com.au> 0.6.9
- Add missing htdel symlink to hosttag package.

* Tue Feb 02 2010 Gavin Carr <gavin@openfusion.com.au> 0.6.8
- Fix bug with htset not deleting host from noskip list if SKIP tag set.

* Wed Jan 13 2010 Gavin Carr <gavin@openfusion.com.au> 0.6.7
- Add --list mode to hosttag.

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

