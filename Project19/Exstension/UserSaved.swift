//
//  UserSaved.swift
//  Exstension
//
//  Created by nikita on 28.02.2023.
//

import UIKit

class UserSaved: Codable {
    var name: String
    var script: String

    init(name: String, script: String) {
        self.name = name
        self.script = script
    }
}
