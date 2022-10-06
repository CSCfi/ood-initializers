mkdir -p $OOD_INSTALL_ROOT/$1/widgets/
mkdir -p $OOD_INSTALL_ROOT/$1/custom_initializers/
mkdir -p $OOD_INSTALL_ROOT/$1/locales
mkdir -p $OOD_INSTALL_ROOT/$1/config/ondemand.d
rsync -r dashboard/ $OOD_INSTALL_ROOT/$1/custom_initializers/dashboard/
rsync locales/en.yml $OOD_INSTALL_ROOT/$1/locales/en.yml
rsync ondemand.d/dashboard.yml $OOD_INSTALL_ROOT/$1/config/ondemand.d/dashboard.yml
rsync -r widgets/ $OOD_INSTALL_ROOT/$1/widgets/
