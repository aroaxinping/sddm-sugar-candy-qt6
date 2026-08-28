//
// This file is part of SDDM Sugar Candy.
// A theme for the Simple Display Desktop Manager.
//
// Copyright (C) 2018–2020 Marian Arlt
//
// SDDM Sugar Candy is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the
// Free Software Foundation, either version 3 of the License, or any later version.
//
// You are required to preserve this and any additional legal notices, either
// contained in this file or in other files that you received along with
// SDDM Sugar Candy that refer to the author(s) in accordance with
// sections §4, §5 and specifically §7b of the GNU General Public License.
//
// SDDM Sugar Candy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SDDM Sugar Candy. If not, see <https://www.gnu.org/licenses/>
//

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "Components"

Pane {
    id: root

    height: config.ScreenHeight || Screen.height
    // Antes: "Screen.ScreenWidth", que no existe -> width quedaba undefined
    // cuando ScreenWidth no estaba configurado en theme.conf.
    width: config.ScreenWidth || Screen.width

    LayoutMirroring.enabled: config.ForceRightToLeft == "true" ? true : Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    padding: config.ScreenPadding
    palette.button: "transparent"
    palette.highlight: config.AccentColor
    palette.text: config.MainColor
    palette.buttonText: config.MainColor
    palette.window: config.BackgroundColor

    font.family: config.Font
    font.pointSize: config.FontSize !== "" ? config.FontSize : parseInt(height / 80)
    focus: true

    //
    // --- Adaptación a pantallas ultrapanorámicas (21:9, 32:9, ...) ---
    //
    // El diseño original dimensiona el formulario como una fracción del ANCHO
    // total (width / 2.5). En un 16:9 eso da ~768px sobre 1920, pero en un
    // 5120x1440 da 2048px: los campos, el reloj y los botones se estiran
    // horizontalmente y el conjunto "se ve ensanchado".
    //
    // Solución independiente de la resolución: limitar el ancho del formulario
    // en función de la ALTURA de la pantalla, que es la dimensión que no crece
    // al hacerse la pantalla más panorámica. El factor 0.72 está elegido para
    // que en 16:9 el resultado sea idéntico al original (1080 * 0.72 ≈ 778 ≈
    // 1920 / 2.5), de modo que nada cambia en pantallas convencionales y sólo
    // se recorta en las muy anchas. En pantallas cuadradas o verticales manda
    // el término width / 2.5 gracias al Math.min.
    //
    // Opción nueva (opcional) en theme.conf: FormMaxWidth="900"
    //   Entero en píxeles. Si se define, sustituye al cálculo automático.
    //   Vacío o ausente => cálculo automático descrito arriba.
    readonly property real formWidthCap: config.FormMaxWidth ? parseInt(config.FormMaxWidth)
                                                             : Math.round(height * 0.72)
    readonly property real formWidth: Math.min(width / 2.5, formWidthCap)

    //
    // --- Fondo de vídeo ---
    //
    // `Background` acepta ahora también un vídeo. No hay opción nueva
    // obligatoria: se decide por la extensión del fichero. Si es un vídeo se
    // carga "VideoBackground.qml" mediante un Loader; si no, se usa el Image
    // de toda la vida y nada cambia.
    //
    // El import de QtMultimedia vive en VideoBackground.qml, no aquí, para que
    // la ausencia del módulo no impida arrancar el greeter. Ver el comentario
    // de cabecera de ese fichero.
    //
    // Opción nueva (opcional) en theme.conf: VideoBackgroundExtensions=""
    //   Lista separada por comas para ampliar las extensiones reconocidas
    //   (p. ej. "ogv,ts"). Vacío o ausente => la lista por defecto de abajo.
    readonly property string backgroundSource: String(config.background || config.Background || "")

    readonly property var videoExtensions: {
        var defaults = ["mp4", "mkv", "webm", "mov", "avi", "m4v"];
        var extra = String(config.VideoBackgroundExtensions || "");
        if (extra.length > 0) {
            var parts = extra.split(",");
            for (var i = 0; i < parts.length; ++i) {
                var e = parts[i].trim().toLowerCase().replace(/^\./, "");
                if (e.length > 0 && defaults.indexOf(e) < 0)
                    defaults.push(e);
            }
        }
        return defaults;
    }

    readonly property bool backgroundIsVideo: {
        // Se ignora una posible query string (?foo) para no romper con urls.
        var path = root.backgroundSource.split("?")[0];
        var dot = path.lastIndexOf(".");
        if (dot < 0)
            return false;
        return root.videoExtensions.indexOf(path.substring(dot + 1).toLowerCase()) >= 0;
    }

    property bool leftleft: config.HaveFormBackground == "true" &&
                            config.PartialBlur == "false" &&
                            config.FormPosition == "left" &&
                            config.BackgroundImageHAlignment == "left"

    property bool leftcenter: config.HaveFormBackground == "true" &&
                              config.PartialBlur == "false" &&
                              config.FormPosition == "left" &&
                              config.BackgroundImageHAlignment == "center"

    property bool rightright: config.HaveFormBackground == "true" &&
                              config.PartialBlur == "false" &&
                              config.FormPosition == "right" &&
                              config.BackgroundImageHAlignment == "right"

    property bool rightcenter: config.HaveFormBackground == "true" &&
                               config.PartialBlur == "false" &&
                               config.FormPosition == "right" &&
                               config.BackgroundImageHAlignment == "center"

    Item {
        id: sizeHelper

        anchors.fill: parent
        height: parent.height
        width: parent.width

        // Capa que hace de fondo "real" para los efectos de desenfoque:
        // el Image de siempre, o el Loader del vídeo cuando toca. Así
        // PartialBlur y FullBlur funcionan igual en ambos casos.
        readonly property Item blurSourceItem: root.backgroundIsVideo ? backgroundVideo : backgroundImage

        Rectangle {
            id: tintLayer
            anchors.fill: parent
            width: parent.width
            height: parent.height
            color: "black"
            opacity: config.DimBackgroundImage
            z: 1
        }

        Rectangle {
            id: formBackground
            anchors.fill: form
            anchors.centerIn: form
            color: root.palette.window
            visible: config.HaveFormBackground == "true" ? true : false
            opacity: config.PartialBlur == "true" ? 0.3 : 1
            z: 1
        }

        LoginForm {
            id: form

            height: virtualKeyboard.state == "visible" ? parent.height - virtualKeyboard.implicitHeight : parent.height
            // Antes: parent.width / 2.5 (desproporcionado en ultrapanorámico).
            width: root.formWidth
            anchors.horizontalCenter: config.FormPosition == "center" ? parent.horizontalCenter : undefined
            anchors.left: config.FormPosition == "left" ? parent.left : undefined
            anchors.right: config.FormPosition == "right" ? parent.right : undefined
            virtualKeyboardActive: virtualKeyboard.state == "visible" ? true : false
            z: 1
        }

        Button {
            id: vkb
            onClicked: virtualKeyboard.switchState()
            visible: virtualKeyboard.status == Loader.Ready && config.ForceHideVirtualKeyboardButton == "false"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: implicitHeight
            anchors.horizontalCenter: form.horizontalCenter
            z: 1
            contentItem: Text {
                text: config.TranslateVirtualKeyboardButton || "Virtual Keyboard"
                color: parent.visualFocus ? palette.highlight : palette.text
                font.pointSize: root.font.pointSize * 0.8
            }
            background: Rectangle {
                id: vkbbg
                color: "transparent"
            }
        }

        Loader {
            id: virtualKeyboard
            source: "Components/VirtualKeyboard.qml"
            state: "hidden"
            property bool keyboardActive: item ? item.active : false
            onKeyboardActiveChanged: keyboardActive ? state = "visible" : state = "hidden"
            // El teclado virtual a 5120px de ancho resulta impracticable: las
            // teclas quedan separadas metro y medio. Se limita igual que el
            // formulario (proporcional a la altura) y se centra. En 16:9 el
            // límite (1080*2 = 2160) es mayor que el ancho, así que sigue
            // ocupando el 100% como antes.
            width: Math.min(parent.width, root.height * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            z: 1
            function switchState() { state = state == "hidden" ? "visible" : "hidden" }
            states: [
                State {
                    name: "visible"
                    PropertyChanges {
                        target: form
                        systemButtonVisibility: false
                        clockVisibility: false
                    }
                    PropertyChanges {
                        target: virtualKeyboard
                        y: root.height - virtualKeyboard.height
                        opacity: 1
                    }
                },
                State {
                    name: "hidden"
                    PropertyChanges {
                        target: virtualKeyboard
                        y: root.height - root.height/4
                        opacity: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "hidden"
                    to: "visible"
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                virtualKeyboard.item.activated = true;
                                Qt.inputMethod.show();
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: virtualKeyboard
                                property: "y"
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                            OpacityAnimator {
                                target: virtualKeyboard
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation {
                                target: virtualKeyboard
                                property: "y"
                                duration: 100
                                easing.type: Easing.InQuad
                            }
                            OpacityAnimator {
                                target: virtualKeyboard
                                duration: 100
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                Qt.inputMethod.hide();
                            }
                        }
                    }
                }
            ]
        }

        // Relleno ("backdrop") para el modo ScaleImageCropped="false".
        //
        // Con PreserveAspectFit una imagen 16:9 en una pantalla 32:9 deja
        // enormes franjas vacías a los lados; con PreserveAspectCrop la misma
        // imagen se amplía x2.7 y se recorta casi todo, que es lo que hace que
        // el fondo se vea "ensanchado" y basto en ultrapanorámico.
        //
        // Este backdrop permite la tercera vía, la que usan los reproductores
        // de vídeo: la imagen se muestra entera (Fit, sin deformar ni recortar)
        // y el espacio sobrante se rellena con una copia recortada y desenfocada
        // de la propia imagen. Es opt-in para no cambiar el aspecto de nadie.
        //
        // Opciones nuevas (opcionales) en theme.conf:
        //   BackgroundFillBlurBackdrop="true"   -> activa el relleno; sólo tiene
        //       efecto si ScaleImageCropped="false".
        //   BackdropBlurRadius="64"             -> fuerza del desenfoque del
        //       relleno. Vacío o ausente => 64.
        Image {
            id: backdropSource
            anchors.fill: backgroundImage
            source: backgroundImage.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            // Sólo sirve de textura para el GaussianBlur de abajo.
            visible: false
        }

        GaussianBlur {
            id: backdrop

            readonly property int blurRadius: config.BackdropBlurRadius ? parseInt(config.BackdropBlurRadius) : 64

            anchors.fill: backgroundImage
            source: backdropSource
            radius: blurRadius
            samples: blurRadius * 2 + 1
            cached: true
            // El backdrop es sólo para imagen: con vídeo, VideoBackground.qml
            // ya coloca el fotograma y no hay copia estática que desenfocar.
            visible: config.BackgroundFillBlurBackdrop == "true" &&
                     config.ScaleImageCropped != "true" &&
                     !root.backgroundIsVideo
            // Por debajo de la imagen nítida (z 0) y del resto del interfaz (z 1).
            z: -1
        }

        Image {
            id: backgroundImage

            height: parent.height
            width: config.HaveFormBackground == "true" && config.FormPosition != "center" && config.PartialBlur != "true" ? parent.width - formBackground.width : parent.width
            anchors.left: leftleft ||
                          leftcenter ?
                                formBackground.right : undefined

            anchors.right: rightright ||
                           rightcenter ?
                                formBackground.left : undefined

            horizontalAlignment: config.BackgroundImageHAlignment == "left" ?
                                 Image.AlignLeft :
                                 config.BackgroundImageHAlignment == "right" ?
                                 Image.AlignRight : Image.AlignHCenter

            verticalAlignment: config.BackgroundImageVAlignment == "top" ?
                               Image.AlignTop :
                               config.BackgroundImageVAlignment == "bottom" ?
                               Image.AlignBottom : Image.AlignVCenter

            // Con fondo de vídeo el Image no carga nada, pero se mantiene en
            // el layout: sigue siendo la referencia de geometría (anchors,
            // ancho reducido por formBackground...) para el vídeo y el blur.
            source: root.backgroundIsVideo ? "" : root.backgroundSource
            visible: !root.backgroundIsVideo
            fillMode: config.ScaleImageCropped == "true" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
            asynchronous: true
            cache: true
            clip: true
            mipmap: true
        }

        // Fondo de vídeo. Sólo se instancia si `Background` apunta a un vídeo.
        //
        // Degradación elegante en dos niveles:
        //   1. Si QtMultimedia no está instalado, el Loader entra en
        //      Loader.Error, queda vacío y se ve el BackgroundColor.
        //   2. Si el módulo está pero el vídeo no se puede decodificar,
        //      VideoBackground.qml se oculta a sí mismo (propiedad `failed`).
        // En ambos casos el greeter sigue siendo usable, que es lo único
        // innegociable aquí.
        Loader {
            id: backgroundVideo

            anchors.fill: backgroundImage
            active: root.backgroundIsVideo
            source: "VideoBackground.qml"
            asynchronous: false

            onLoaded: {
                item.videoSource = root.backgroundSource;
                item.cropped = config.ScaleImageCropped != "false";
                item.hAlignment = config.BackgroundImageHAlignment || "center";
                item.vAlignment = config.BackgroundImageVAlignment || "center";
            }

            onStatusChanged: {
                if (status == Loader.Error)
                    console.warn("Sugar Candy: no se pudo cargar el fondo de vídeo. " +
                                 "¿Falta el módulo QtMultimedia (paquete qt6-multimedia)? " +
                                 "Se usará el color de fondo.");
            }
        }

        MouseArea {
            anchors.fill: backgroundImage
            onClicked: parent.forceActiveFocus()
        }

        ShaderEffectSource {
            id: blurMask

            sourceItem: sizeHelper.blurSourceItem
            width: form.width
            height: parent.height
            anchors.centerIn: form
            sourceRect: Qt.rect(x,y,width,height)
            visible: config.FullBlur == "true" || config.PartialBlur == "true" ? true : false
        }

        GaussianBlur {
            id: blur

            height: parent.height
            width: config.FullBlur == "true" ? parent.width : form.width
            source: config.FullBlur == "true" ? sizeHelper.blurSourceItem : blurMask
            radius: config.BlurRadius
            samples: config.BlurRadius * 2 + 1
            // Con vídeo NO se puede cachear: el caché congela el primer
            // fotograma y el fondo se quedaría quieto.
            cached: !root.backgroundIsVideo
            anchors.centerIn: config.FullBlur == "true" ? parent : form
            visible: config.FullBlur == "true" || config.PartialBlur == "true" ? true : false
        }
    }
}
