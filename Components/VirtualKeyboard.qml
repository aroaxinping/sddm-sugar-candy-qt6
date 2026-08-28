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

    // `Qt.inputMethod` está tipado como QObject, así que qmllint no puede
    // resolver `visible` y avisa de missing-property; la propiedad existe en
    // tiempo de ejecución (QInputMethod::visible).
    active: activated && Qt.inputMethod.visible // qmllint disable missing-property
    visible: active
}
