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
import QtQuick.VirtualKeyboard

InputPanel {
    id: virtualKeyboard
    property bool activated: false

    // NO configurar aquí VirtualKeyboardSettings.layout / layoutPath.
    //
    // Es tentador "arreglar" el teclado forzando una página concreta desde
    // Component.onCompleted (otros temas SDDM lo hacen: SilentSDDM pone
    // VirtualKeyboardSettings.layout = "symbols"). Eso es precisamente lo que
    // rompe la tecla shift: en la página de símbolos shift no da mayúsculas,
    // solo alterna entre grupos de símbolos. Dejando la propiedad sin tocar,
    // Keyboard.qml calcula `layoutType` solo ("main" para un campo de texto
    // normal) y `onActiveChanged` limpia `symbolMode` cada vez que el panel
    // pasa a activo, que es el comportamiento correcto.
    //
    // Tampoco hay que compensar nada por el campo de contraseña: aunque
    // QQuickTextInput añade Qt.ImhSensitiveData / ImhHiddenText /
    // ImhNoAutoUppercase cuando echoMode es Password, esos flags solo apagan
    // la autocapitalización (ShiftHandler.autoCapitalizationEnabled), no la
    // tecla shift (ShiftHandler.toggleShiftEnabled sigue siendo true).
    // Verificado contra Qt 6.11.2: con este mismo wrapper, pulsar shift y
    // luego una letra inserta la mayúscula en un TextField con
    // echoMode: TextInput.Password.

    // IMPORTANTE — si shift no funciona (o el panel no llega a aparecer), el
    // fallo NO está en este fichero: es configuración de SDDM.
    //
    // SDDM 0.21.0 descarta a propósito el teclado virtual cuando el greeter
    // corre sobre Wayland. En src/greeter/GreeterApp.cpp, antes de construir
    // QGuiApplication:
    //
    //     QString inputMethod = SDDM::mainConfig.InputMethod.get();
    //     if (platform.startsWith("wayland") && inputMethod == "qtvirtualkeyboard")
    //         inputMethod = QString{};              // <-- se vacía
    //     if (!inputMethod.isEmpty())
    //         qputenv("QT_IM_MODULE", inputMethod.toLocal8Bit());
    //
    // O sea: con DisplayServer=wayland, `InputMethod=qtvirtualkeyboard` se
    // ignora y QT_IM_MODULE nunca se define. Sin esa variable el plugin
    // libqtvirtualkeyboardplugin.so no es el platform input context, y
    // entonces InputContext.priv.inputItem es null y
    // ShiftHandler.toggleShiftEnabled queda en false: shift muerta. Medido con
    // Qt 6.11.2 sobre este mismo wrapper (sin QT_IM_MODULE: active=false,
    // toggleShiftEnabled=false, inputItem=null; con QT_IM_MODULE=qtvirtualkeyboard:
    // active=true, toggleShiftEnabled=true, inputItem=<TextField>).
    //
    // Por eso el síntoma es idéntico en cualquier tema (SilentSDDM incluido):
    // es de sistema, no del QML. Arreglo, en /etc/sddm.conf.d/ (GreeterEnvironment
    // se inyecta en el proceso del greeter desde src/helper/Backend.cpp y
    // GreeterApp nunca la borra, así que sobrevive al descarte de arriba):
    //
    //     [General]
    //     GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QT_IM_MODULE=qtvirtualkeyboard
    //
    // Ojo: GreeterEnvironment se sustituye entera, no se acumula, así que hay
    // que repetir el QT_WAYLAND_SHELL_INTEGRATION que trae
    // /usr/lib/sddm/sddm.conf.d/zz-wayland.conf o el greeter pierde layer-shell.

    // `Qt.inputMethod` está tipado como QObject, así que qmllint no puede
    // resolver `visible` y avisa de missing-property; la propiedad existe en
    // tiempo de ejecución (QInputMethod::visible).
    active: activated && Qt.inputMethod.visible // qmllint disable missing-property
    visible: active
}
