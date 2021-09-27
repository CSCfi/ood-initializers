rsync --inplace dashboard/ood.rb /ood-full/$1/custom_initializers/dashboard/ood.rb
rsync locales/en.yml /ood-full/$1/locales/en.yml
rsync ondemand.d/dashboard.yml /ood-full/$1/config/ondemand.d/dashboard.yml
rsync widgets/_logo.html.erb /ood-full/$1/widgets/_logo.html.erb
