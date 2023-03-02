%define config_path /etc/ood/config/
%define dashboard_path %{config_path}apps/dashboard/
%define util_path /appl/opt/ood

Name:           ood-initializers
Version:        13
Release:        1%{?dist}
Summary:        Open on Demand initializers

BuildArch:      noarch

License:        MIT
Source:         %{name}-%{version}.tar.bz2

Requires:       ondemand
Requires:       ood-util

# Disable debuginfo
%global debug_package %{nil}

%description
Open on Demand initializers

%prep
%setup -q

%build

%install

%__install -m 0755 -d %{buildroot}%{config_path}/ondemand.d
%__install -m 0755 -d %{buildroot}%{dashboard_path}{initializers,locales}
%__install -m 0755 -d %{buildroot}%{dashboard_path}views/widgets/{grafana,notifications}
%__install -m 0755 -d %{buildroot}%{dashboard_path}views/layouts

%__install -m 0644 -D dashboard/*.rb %{buildroot}%{dashboard_path}initializers

%__install -m 0644 -D widgets/*.erb               %{buildroot}%{dashboard_path}views/widgets
%__install -m 0644 -D widgets/grafana/*.erb       %{buildroot}%{dashboard_path}views/widgets/grafana
%__install -m 0644 -D widgets/notifications/*.erb %{buildroot}%{dashboard_path}views/widgets/notifications

%__install -m 0644 locales/en.yml           %{buildroot}%{dashboard_path}locales/en.yml
%__install -m 0644 ondemand.d/dashboard.yml %{buildroot}%{config_path}ondemand.d/dashboard.yml

# TODO: pull these from ondemand rpm and patch them here?
%__install -m 0644 application.html.erb %{buildroot}%{dashboard_path}views/layouts/application.html.erb
%__install -m 0644 _footer.html.erb     %{buildroot}%{dashboard_path}views/layouts/_footer.html.erb

echo 'CSC_OOD_DEPS_PATH="%{util_path}"' > %{buildroot}%{dashboard_path}env
echo 'CSC_OOD_RELEASE="%{version}"' >>    %{buildroot}%{dashboard_path}env

%files

%{config_path}

%changelog
* Fri Mar 3 2023 Robin Karlsson <robin.karlsson@csc.fi>
- Basic working version of RPM

* Fri Feb 23 2023 Sami Ilvonen <sami.ilvonen@csc.fi>
- Initial version
