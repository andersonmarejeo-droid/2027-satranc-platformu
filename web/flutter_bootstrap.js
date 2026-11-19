{{flutter_js}}
{{flutter_build_config}}

const loading = document.getElementById('loading');
const chessWebConfig = { canvasKitBaseUrl: 'canvaskit/' };
window.addEventListener('flutter-first-frame', () => loading?.remove(), { once: true });
function showStartupError(error) {
  console.error('Chess Platform could not start.', error);
  if (loading) loading.textContent = 'Uygulama açılamadı. Sayfayı yenileyebilirsin.';
}

async function startChess() {
  try {
    await _flutter.loader.load({
      config: chessWebConfig,
      onEntrypointLoaded: async function (engineInitializer) {
        try {
          const appRunner = await engineInitializer.initializeEngine(chessWebConfig);
          await appRunner.runApp();
        } catch (error) {
          showStartupError(error);
        }
      },
    });
  } catch (error) {
    showStartupError(error);
  }
}
startChess();
