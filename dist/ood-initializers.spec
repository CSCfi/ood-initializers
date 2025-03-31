%define config_path /etc/ood/config/
%define dashboard_path %{config_path}apps/dashboard/
%define deps_path /var/www/ood/deps
%define assets_path /var/www/ood/assets/
%define layouts_path %{dashboard_path}/app/views/layouts/

Name:           ood-initializers
Version:        7
Release:        1%{?dist}
Summary:        Open on Demand initializers

BuildArch:      noarch

License:        MIT

Source:        %{name}-%{version}.tar.bz2

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

%__install -m 0755 -d %{buildroot}%{config_path}/{ondemand.d,locales}
%__install -m 0755 -d %{buildroot}%{dashboard_path}initializers
%__install -m 0755 -d %{buildroot}%{dashboard_path}views/widgets/{grafana,notifications}
%__install -m 0755 -d %{buildroot}%{dashboard_path}views/layouts
%__install -m 0755 -d %{buildroot}%{assets_path}{scripts,stylesheets}

%__install -m 0644 -D dashboard/*.rb %{buildroot}%{dashboard_path}initializers

%__install -m 0644 -D widgets/*.erb               %{buildroot}%{dashboard_path}views/widgets
%__install -m 0644 -D widgets/grafana/*.erb       %{buildroot}%{dashboard_path}views/widgets/grafana
%__install -m 0644 -D widgets/notifications/*.erb %{buildroot}%{dashboard_path}views/widgets/notifications

%__install -m 0644 locales/en.yml           %{buildroot}%{config_path}locales/en.yml
%__install -m 0644 ondemand.d/dashboard.yml.erb %{buildroot}%{config_path}ondemand.d/dashboard.yml.erb

%__install -m 0644 _footer.html.erb               %{buildroot}%{dashboard_path}views/layouts/_footer.html.erb
%__install -m 0644 -D stylesheets/dashboard.css   %{buildroot}%{assets_path}stylesheets/
%__install -m 0644 -D javascript/*.js             %{buildroot}%{assets_path}scripts

%__install -m 0644 env %{buildroot}%{dashboard_path}

%files

%{config_path}
%{assets_path}

%changelog
* Fri Mar 3 2023 Robin Karlsson <robin.karlsson@csc.fi>
- Basic working version of RPM

* Fri Feb 23 2023 Sami Ilvonen <sami.ilvonen@csc.fi>
- Initial version
