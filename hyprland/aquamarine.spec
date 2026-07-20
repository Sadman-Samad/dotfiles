Name:    aquamarine
Version: 0.9.5
Release: 4.rebuilt.fc44%{?dist}
Summary: A very light Linux rendering backend library (rebuilt for F44)
License: BSD-3-Clause
URL:     https://github.com/hyprwm/aquamarine
Source0: aquamarine-%{version}.tar.gz

BuildRequires: cmake gcc-c++ make pkgconf-pkg-config
BuildRequires: pkgconfig(libseat)
BuildRequires: pkgconfig(libinput)
BuildRequires: pkgconfig(wayland-client)
BuildRequires: pkgconfig(wayland-protocols)
BuildRequires: pkgconfig(hyprutils)
BuildRequires: pkgconfig(pixman-1)
BuildRequires: pkgconfig(libdrm)
BuildRequires: pkgconfig(gbm)
BuildRequires: pkgconfig(libudev)
BuildRequires: pkgconfig(libdisplay-info)
BuildRequires: pkgconfig(glesv2)
BuildRequires: pkgconfig(gl)
Requires:      hwdata
Requires:      hyprwayland-scanner

%description
A very light Linux rendering backend library, rebuilt against Fedora 44's
libdisplay-info.so.3 to satisfy the solopasha/hyprland COPR dependencies.

%prep
%setup -q -n aquamarine-%{version}

%build
%cmake -DCMAKE_BUILD_TYPE=Release
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%{_libdir}/libaquamarine.so.*
%{_libdir}/libaquamarine.so
%{_includedir}/aquamarine/
%{_libdir}/pkgconfig/aquamarine.pc

%changelog
* Sun Jul 20 2026 Sadman Samad <sadmansamadlian@gmail.com> - 0.9.5-4
- Rebuild against Fedora 44 libdisplay-info.so.3
