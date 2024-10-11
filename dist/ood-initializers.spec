%define config_path /etc/ood/config/
%define dashboard_path %{config_path}apps/dashboard/
%define deps_path /var/www/ood/deps
%define assets_path /var/www/ood/assets/

# OOD version from GitHub to use for patching application.html.erb and _footer.html.erb.
%define ood_version 3.1.0
# Required for having rpmbuild download sources from GitHub automatically.
%undefine _disable_source_fetch

Name:           ood-initializers
Version:        10
Release:        1%{?dist}
Summary:        Open on Demand initializers

BuildArch:      noarch

License:        MIT

Source0:        %{name}-%{version}.tar.bz2
Source1:        https://github.com/OSC/ondemand/releases/download/v%{ood_version}/ondemand-%{ood_version}.tar.gz

Requires:       ondemand
Requires:       ood-util
Requires:       ood-lustre-quota

%define git_src_path %{name}-%{version}/
%define ood_layouts_path ondemand-%{ood_version}/apps/dashboard/app/views/layouts/

# Disable debuginfo
%global debug_package %{nil}

%description
Open on Demand initializers

%prep
%setup -a 0 -q
%setup -a 1 -c -n ondemand-%{ood_version}

%build

%install

%__install -m 0755 -d %{buildroot}%{config_path}/{ondemand.d,locales}
%__install -m 0755 -d %{buildroot}%{dashboard_path}initializers
%__install -m 0755 -d %{buildroot}%{dashboard_path}views/widgets/{grafana,notifications}
%__install -m 0755 -d %{buildroot}%{dashboard_path}views/layouts
%__install -m 0755 -d %{buildroot}%{assets_path}scripts
%__install -m 0755 -d %{buildroot}%{assets_path}stylesheets

%__install -m 0644 -D %{git_src_path}dashboard/*.rb %{buildroot}%{dashboard_path}initializers

%__install -m 0644 -D %{git_src_path}widgets/*.erb               %{buildroot}%{dashboard_path}views/widgets
%__install -m 0644 -D %{git_src_path}widgets/grafana/*.erb       %{buildroot}%{dashboard_path}views/widgets/grafana
%__install -m 0644 -D %{git_src_path}widgets/notifications/*.erb %{buildroot}%{dashboard_path}views/widgets/notifications

%__install -m 0644 -D %{git_src_path}stylesheets/dashboard.css  %{buildroot}%{assets_path}stylesheets

%__install -m 0644 %{git_src_path}locales/en.yml           %{buildroot}%{config_path}locales/en.yml
%__install -m 0644 %{git_src_path}ondemand.d/dashboard.yml.erb %{buildroot}%{config_path}ondemand.d/dashboard.yml.erb

%__install -m 0644 %{ood_layouts_path}application.html.erb                %{buildroot}%{dashboard_path}views/layouts/application.html.erb
%__install -m 0644 %{ood_layouts_path}_footer.html.erb                    %{buildroot}%{dashboard_path}views/layouts/_footer.html.erb
%__patch %{buildroot}%{dashboard_path}views/layouts/application.html.erb  %{git_src_path}application.html.erb.patch
%__patch %{buildroot}%{dashboard_path}views/layouts/_footer.html.erb      %{git_src_path}_footer.html.erb.patch

%__install -m 0644 -D %{git_src_path}javascript/*.js    %{buildroot}%{assets_path}scripts

%__install -m 0644 %{git_src_path}env %{buildroot}%{dashboard_path}

%files

%{config_path}
%{assets_path}

%changelog
* Fri Mar 3 2023 Robin Karlsson <robin.karlsson@csc.fi>
- Basic working version of RPM

* Fri Feb 23 2023 Sami Ilvonen <sami.ilvonen@csc.fi>
- Initial version
