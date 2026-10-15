# DataWidget 🦝

App y widget para iPhone que muestran los datos móviles restantes de Telcel, con un mapache.

- La app muestra al mapache animado y tus datos.
- El widget se actualiza solo; tocar al mapache refresca sin abrir la app.
- Los datos vienen de un repositorio privado (`datos.json`); el token de GitHub se pega dentro de la app y del widget, nunca va en este código.

Cada cambio en `main` se compila en GitHub Actions y el `.ipa` sin firmar se publica en **Releases** para instalarlo con AltStore o SideStore.
