{{flutter_js}}
{{flutter_build_config}}

// Sem `serviceWorkerSettings`: o service worker do FONAR é o
// servico_offline.js, registrado no index.html, que guarda a versão inteira
// para abrir sem internet. Dois service workers no mesmo escopo brigariam
// pelo mesmo cache.
_flutter.loader.load();
