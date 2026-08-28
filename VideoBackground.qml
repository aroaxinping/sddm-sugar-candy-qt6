//
// This file is part of SDDM Sugar Candy — Qt6 port.
//
// Copyright (C) 2018–2020 Marian Arlt (original theme)
//
// SDDM Sugar Candy is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the
// Free Software Foundation, either version 3 of the License, or any later version.
//
// SDDM Sugar Candy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SDDM Sugar Candy. If not, see <https://www.gnu.org/licenses/>
//

// ----------------------------------------------------------------------------
// Fondo de vídeo.
//
// Este fichero existe SEPARADO de Main.qml a propósito. `import QtMultimedia`
// es un import duro: si el módulo no está instalado (qt6-multimedia), el
// fichero que lo declara no compila. Si estuviera en Main.qml, el greeter
// entero moriría y el usuario se quedaría sin poder entrar al sistema.
//
// Aislado aquí y cargado con un Loader, el fallo se degrada a
// `Loader.status == Loader.Error`: el Loader queda vacío, se ve el
// BackgroundColor del tema y todo lo demás (formulario, teclado, botones)
// sigue funcionando con normalidad.
//
// Main.qml rellena las propiedades de abajo en `onLoaded`.
// ----------------------------------------------------------------------------

import QtQuick
import QtMultimedia

Item {
    id: videoRoot

    // Ruta del vídeo. La rellena Main.qml.
    property url videoSource

    // Equivalente a ScaleImageCropped: true = recortar para cubrir,
    // false = mostrar el fotograma entero (deja franjas).
    property bool cropped: true

    // Equivalentes a BackgroundImageHAlignment / VAlignment.
    // VideoOutput no tiene alineación propia, así que se emula colocando a
    // mano el VideoOutput dentro de este Item, que hace de recorte.
    property string hAlignment: "center"
    property string vAlignment: "center"

    // true si el vídeo no se pudo reproducir (códec ausente, fichero corrupto,
    // ruta inexistente...). Nos ocultamos solos para dejar ver el color de
    // fondo en vez de un rectángulo negro.
    property bool failed: false

    clip: true
    visible: !failed

    // Main.qml asigna `videoSource` en onLoaded, es decir DESPUÉS de que este
    // componente se haya completado. Por eso no basta con un play() en
    // Component.onCompleted: hay que (re)arrancar cuando llega la ruta.
    onVideoSourceChanged: startPlayback()

    function startPlayback() {
        if (String(videoRoot.videoSource).length > 0)
            player.play();
    }

    // Relación de aspecto real del vídeo.
    // Se prefiere la resolución de los metadatos, que está disponible en
    // cuanto se abre el fichero; el sourceRect del VideoOutput sólo se rellena
    // al llegar el primer fotograma. 0 = todavía desconocida, en cuyo caso se
    // ocupa todo el área disponible.
    readonly property size metaResolution: player.metaData
                                           ? player.metaData.value(MediaMetaData.Resolution) || Qt.size(0, 0)
                                           : Qt.size(0, 0)

    readonly property real aspect: metaResolution.height > 0
                                   ? metaResolution.width / metaResolution.height
                                   : (output.sourceRect.height > 0
                                      ? output.sourceRect.width / output.sourceRect.height
                                      : 0)

    readonly property real contentWidth: aspect <= 0
                                          ? width
                                          : (cropped ? Math.max(width, height * aspect)
                                                     : Math.min(width, height * aspect))

    readonly property real contentHeight: aspect <= 0 ? height : contentWidth / aspect

    VideoOutput {
        id: output

        // El tamaño ya se calcula con la proporción exacta arriba, así que
        // cualquier fillMode que respete el aspecto da el mismo resultado.
        fillMode: VideoOutput.PreserveAspectFit

        width: videoRoot.contentWidth
        height: videoRoot.contentHeight

        x: videoRoot.hAlignment == "left" ? 0
           : videoRoot.hAlignment == "right" ? videoRoot.width - width
           : (videoRoot.width - width) / 2

        y: videoRoot.vAlignment == "top" ? 0
           : videoRoot.vAlignment == "bottom" ? videoRoot.height - height
           : (videoRoot.height - height) / 2
    }

    MediaPlayer {
        id: player

        source: videoRoot.videoSource
        videoOutput: output

        // SIN sonido: en Qt6 un MediaPlayer sin `audioOutput` no reproduce
        // audio en absoluto. Es más fiable que poner el volumen a 0 y evita
        // depender de que haya servidor de audio en la sesión del greeter.

        loops: MediaPlayer.Infinite

        onErrorOccurred: function(error, errorString) {
            console.warn("Sugar Candy: no se pudo reproducir el fondo de vídeo:", errorString);
            videoRoot.failed = true;
        }

        onMediaStatusChanged: {
            // NoMedia queda fuera a propósito: es el estado inicial legítimo
            // mientras Main.qml todavía no ha asignado `videoSource`.
            if (mediaStatus == MediaPlayer.InvalidMedia) {
                videoRoot.failed = true;
            } else if (mediaStatus == MediaPlayer.LoadedMedia || mediaStatus == MediaPlayer.BufferedMedia) {
                videoRoot.failed = false;
                // Red de seguridad: si por lo que sea el play() anterior no
                // prendió, arrancamos en cuanto el medio está listo.
                if (playbackState != MediaPlayer.PlayingState)
                    play();
            }
        }

        Component.onCompleted: videoRoot.startPlayback()
    }
}
