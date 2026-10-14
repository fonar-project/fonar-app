// O FONAR abre sem internet (US42).
//
// A versão no navegador é a do iPhone, e a regra do app vale para ela: a
// gravação funciona offline, e a fila sobe quando a conexão volta. Para isso
// a página precisa abrir sem rede — é o que este service worker faz.
//
// - Na instalação, guarda de uma vez todos os arquivos da versão, pela lista
//   que `tool/lista_offline.py` escreve no build (arquivos_offline.json).
// - Daí em diante, serve do que guardou. Abrir a página é abrir sempre a
//   mesma versão inteira, nunca metade de uma e metade de outra.
// - Versão nova publicada: o carimbo abaixo muda, o navegador instala este
//   arquivo de novo, e a próxima abertura já é a nova.
//
// Só arquivos da própria versão, da mesma origem. A API, o Firebase e
// qualquer outra origem passam direto: dado de paciente nunca vai para este
// cache.

const VERSAO = '__VERSAO_OFFLINE__';
const PREFIXO = 'fonar-';
const CACHE = PREFIXO + VERSAO;

self.addEventListener('install', (evento) => {
  evento.waitUntil(
    (async () => {
      const resposta = await fetch('arquivos_offline.json', { cache: 'no-store' });
      const { arquivos } = await resposta.json();
      const cache = await caches.open(CACHE);
      await cache.addAll(arquivos);
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (evento) => {
  evento.waitUntil(
    (async () => {
      for (const nome of await caches.keys()) {
        if (nome.startsWith(PREFIXO) && nome !== CACHE) {
          await caches.delete(nome);
        }
      }
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (evento) => {
  const pedido = evento.request;
  if (pedido.method !== 'GET') return;
  const endereco = new URL(pedido.url);
  if (endereco.origin !== self.location.origin) return;

  evento.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      // Abrir a página é sempre o index.html desta versão: as rotas do app
      // vivem depois do #, e o arquivo é um só.
      const chave = pedido.mode === 'navigate' ? 'index.html' : pedido;
      const guardada = await cache.match(chave, { ignoreSearch: true });
      if (guardada) return guardada;

      const resposta = await fetch(pedido);
      // O que não estava na lista e o navegador pediu (o CanvasKit de um
      // navegador Chromium, por exemplo) fica guardado da primeira vez.
      if (resposta.ok && resposta.type === 'basic') {
        await cache.put(pedido, resposta.clone());
      }
      return resposta;
    })(),
  );
});
