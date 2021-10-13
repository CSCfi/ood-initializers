mkdir -p /ood-full/$1/widgets/
mkdir -p /ood-full/$1/custom_initializers/
mkdir -p /ood-full/$1/locales
mkdir -p /ood-full/$1/config/ondemand.d
rsync --inplace dashboard/ood.rb /ood-full/$1/custom_initializers/dashboard/ood.rb
rsync locales/en.yml /ood-full/$1/locales/en.yml
rsync ondemand.d/dashboard.yml /ood-full/$1/config/ondemand.d/dashboard.yml
rsync widgets/ /ood-full/$1/widgets/
