//
//  SonicSnailApp.swift
//  SonicSnail
//
//  Created by Jerin Raisa on 2022-07-21.
//

import SwiftUI

@available(iOS 14.0, *)
@main
struct SonicSnailApp: App {
    @State private var email = "test@test.com"
    @State private var password = "1234567"
    @State private var name = ""
    @State private var checked = true
    @State private var input = "Jerin"
    @State private var number = 50.0
    
    @available(iOS 14.0, *)
    var body: some Scene {
        WindowGroup {
            Content(userEmail: $email, userPassword: $password, template: $name, state: $checked, vol: $number)
        }
    }
}
