guesanumber_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

guesanumber_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
]

guesanumber_sources += gnome.compile_resources('guesanumber-resources',
  'guesanumber.gresource.xml',
  c_name: 'guesanumber'
)

executable('guesanumber', guesanumber_sources,
  dependencies: guesanumber_deps,
  include_directories: config_inc,
       install: true,
)
