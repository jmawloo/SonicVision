//
//  ContentView.swift
//  SonicSnail
//
//  Created by Jerin Raisa on 2022-07-21.
//

import SwiftUI

struct CheckBoxView: View {
    @Binding var checked: Bool

    var body: some View {
        Image(systemName: checked ? "checkmark.square.fill" : "square")
            .foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
            .onTapGesture {
                self.checked.toggle()
            }
    }
}

struct LoginPage: View {
    
    @Binding var userEmail: String
    @Binding var userPassword: String
    @Binding var template: String
    @Binding var state: Bool
    @Binding var vol: Double
    
//    init() {
//      let coloredAppearance = UINavigationBarAppearance()
//      coloredAppearance.configureWithOpaqueBackground()
//      coloredAppearance.backgroundColor = UIColor(Color(red: 0/255, green: 110/255, blue: 230/255))
//      coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//      coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
//
//      UINavigationBar.appearance().standardAppearance = coloredAppearance
//      UINavigationBar.appearance().compactAppearance = coloredAppearance
//      UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
//
//      UINavigationBar.appearance().tintColor = .white
//    }
    

    var body: some View {
        NavigationView {
        VStack(alignment: .center) {
            Image("bolt")
                .resizable()
                .frame(width: 50.0, height: 95.0)
            Text("SonicVision")
                .fontWeight(.bold)
                .padding(.vertical, 15.0)
                .font(.system(size: 30))
                .foregroundColor(Color(red: 0/255, green: 98/255, blue: 204/255))
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                .font(.system(size: 11))
                .padding(.top, -10)
            Form {
                Text("Email Address")
                    .padding(.bottom, -10)
                    .font(.system(size: 14))
                    .listRowSeparator(.hidden)
                TextField("name@company.com", text: $userEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .listRowSeparator(.hidden)
                .padding(.top, -10)
                
                Text("Password")
                    .padding(.bottom, -10)
                    .font(.system(size: 14))
                    .listRowSeparator(.hidden)
                SecureField("Enter your password", text: $userPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .listRowSeparator(.hidden)
                .padding(.top, -10)

            }
            .onAppear { // ADD THESE AFTER YOUR FORM VIEW
                UITableView.appearance().backgroundColor = .clear
            }
            .padding(.leading, -40)
            .padding(.trailing, -40)
            .background(.white) // Add your background color
            .frame(width: .infinity, height: 215)
            .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.white/*@END_MENU_TOKEN@*/)
            
            NavigationLink(destination: ForgotPasswordView(userEmail: $userEmail)) {
                Text("Forgot Password?")
                    .font(.system(size: 12))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 48/255, green: 147/255, blue: 255/255))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, -10)
            .padding(.bottom, 105)
            
            NavigationLink(destination: Configure(name: $template, userEmail: $userEmail, userPassword: $userPassword, template: $template, state: $state, vol: $vol)) {
            Button {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
            }label: {
                Text("Sign In").bold()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(red: 0/255, green: 122/255, blue: 255/255))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            
            NavigationLink(destination: CreateAccountPage(userEmail: $userEmail, userPassword: $userPassword, name: $template, checked: $state, number: $vol)) {
                HStack(spacing: 5) {
                    Text("Don't have an account?")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .frame(alignment: .center)
                    Text("Create account")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                        .frame(alignment: .center)
                }

            }
            .padding(.top, 35)
            
            
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(.horizontal, 35.0).padding(.top, -50)
        }.navigationBarBackButtonHidden(true)
    }
}

struct CreateAccountPage: View {
    @Binding var userEmail: String
    @Binding var userPassword: String
    @Binding var name: String
    @Binding var checked: Bool
    @Binding var number: Double

    
    var body: some View {
        VStack(alignment: .center) {
            Image("bolt")
                .resizable()
                .frame(width: 50.0, height: 95.0)
                .padding(.top, -60)
            Text("Create Account")
                .fontWeight(.bold)
                .padding(.vertical, 15.0)
                .font(.system(size: 30))
                .foregroundColor(Color(red: 0/255, green: 98/255, blue: 204/255))
            Text("Nec nihil affert partiendo ne, quo no iisque etiam tacimates sed conceptam.")
                .font(.system(size: 15))
                .padding(.top, -10)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

            Form {
                VStack(alignment: .leading){
                    Text("Name")
                        .font(.system(size: 14))
                        .listRowSeparator(.hidden)
                    TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .listRowSeparator(.hidden)
                }.listRowSeparator(.hidden).padding(.bottom, 10)
                
                VStack(alignment: .leading){
                    Text("Email Address")
                        .font(.system(size: 14))
                        .listRowSeparator(.hidden)
                    TextField("name@company.com", text: $userEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .listRowSeparator(.hidden)
                }.listRowSeparator(.hidden).padding(.bottom, 10)
                
                VStack(alignment: .leading){
                    Text("Password")
                        .font(.system(size: 14))
                        .listRowSeparator(.hidden)
                    SecureField("Enter your password", text: $userPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .listRowSeparator(.hidden)
                }.listRowSeparator(.hidden)
            }
            .onAppear { // ADD THESE AFTER YOUR FORM VIEW
                UITableView.appearance().backgroundColor = .clear
            }
            .padding(.leading, -40)
            .padding(.trailing, -40)
            .background(.white) // Add your background color
            .frame(width: .infinity, height: 300)
            .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.white/*@END_MENU_TOKEN@*/)
            
            HStack(spacing: 5){
                CheckBoxView(checked: $checked)
                HStack(spacing: 5) {
                    Text("I agree with our")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(alignment: .center)
                    NavigationLink(destination: TermsView()) {
                    Text("Terms and Conditions")
                        .font(.system(size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                        .frame(alignment: .center)
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 40).padding(.top, -20)

            NavigationLink(destination: Configure(name: $name, userEmail: $userEmail, userPassword: $userPassword, template: $name, state: $checked, vol: $number)) {
            Button {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
            }label: {
                Text("Create account").bold()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(red: 0/255, green: 122/255, blue: 255/255))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            
            NavigationLink(destination: LoginPage(userEmail: $userEmail, userPassword: $userPassword, template: $name, state: $checked, vol: $number)) {
                HStack(spacing: 5) {
                    Text("Already have an account?")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .frame(alignment: .center)
                    Text("Sign In")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                        .frame(alignment: .center)
                }

            }
            .padding(.top, 35)
            
            
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(.horizontal, 35.0).navigationBarBackButtonHidden(true)
        
    }
}

struct ForgotPasswordView: View {
    
    @Binding var userEmail: String
    
    var body: some View {
        VStack{
            VStack{
                Text("Forgot Password?")
                    .fontWeight(.bold)
                    .padding(.vertical, 15.0)
                    .font(.system(size: 30))
                    .foregroundColor(Color(red: 0/255, green: 98/255, blue: 204/255))
                
                Text("Mel ea numquam efficiendi appellantur, eu vix reque inermis propriae, animal scaevola.")
                    .font(.system(size: 15))
                    .padding(.top, -10)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            .padding(.top, 20.0)
            
            Form {
                Text("Email Address")
                    .padding(.bottom, -10)
                    .font(.system(size: 14))
                    .listRowSeparator(.hidden)
                TextField("name@company.com", text: $userEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .listRowSeparator(.hidden)
                .padding(.top, -10)

            }
            .onAppear { // ADD THESE AFTER YOUR FORM VIEW
                UITableView.appearance().backgroundColor = .clear
            }
            .padding(.leading, -40)
            .padding(.trailing, -40)
            .background(.white) // Add your background color
            .frame(width: .infinity, height: 400)
            .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.white/*@END_MENU_TOKEN@*/)
            
            Button {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
            }label: {
                Text("Continue").bold()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(red: 0/255, green: 122/255, blue: 255/255))
                .foregroundColor(.white)
                .cornerRadius(14)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(.horizontal, 35.0)
            .navigationBarTitle(Text("Password Reset"), displayMode: .inline)
        
    }
}

struct ResetPasswordView: View {
    
    @Binding var password: String
    
    var body: some View {
        VStack{
            VStack{
                Text("Reset Password")
                    .fontWeight(.bold)
                    .padding(.vertical, 15.0)
                    .font(.system(size: 30))
                    .foregroundColor(Color(red: 0/255, green: 98/255, blue: 204/255))
                
                Text("Mel ea numquam efficiendi appellantur, eu vix reque inermis propriae, animal scaevola.")
                    .font(.system(size: 15))
                    .padding(.top, -10)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            .padding(.top, 20.0)
            
            Form {
                Text("New Password")
                    .padding(.bottom, -10)
                    .font(.system(size: 14))
                    .listRowSeparator(.hidden)
                SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .listRowSeparator(.hidden)
                .padding(.top, -10)
                Text("Confirm New Password")
                    .padding(.bottom, -10)
                    .font(.system(size: 14))
                    .listRowSeparator(.hidden)
                SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .listRowSeparator(.hidden)
                .padding(.top, -10)

            }
            .onAppear { // ADD THESE AFTER YOUR FORM VIEW
                UITableView.appearance().backgroundColor = .clear
            }
            .padding(.leading, -40)
            .padding(.trailing, -40)
            .background(.white) // Add your background color
            .frame(width: .infinity, height: 400)
            .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.white/*@END_MENU_TOKEN@*/)
            
            Button {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
            }label: {
                Text("Confirm").bold()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(red: 0/255, green: 122/255, blue: 255/255))
                .foregroundColor(.white)
                .cornerRadius(14)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(.horizontal, 35.0)
            .navigationBarTitle(Text("Password Reset"), displayMode: .inline)
        
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView{
        VStack {
            Text("About")
                .bold()
                .font(.system(size: 20))
                .padding(.bottom, 25)
                .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Diam phasellus vestibulum lorem sed risus ultricies tristique nulla. Sit amet tellus cras adipiscing. Suspendisse ultrices gravida dictum fusce ut placerat orci nulla. Interdum consectetur libero id faucibus. Libero id faucibus nisl tincidunt eget nullam. A arcu cursus vitae congue mauris rhoncus. Augue neque gravida in fermentum et. Interdum varius sit amet mattis vulputate. Gravida rutrum quisque non tellus orci ac auctor augue. Faucibus scelerisque eleifend donec pretium vulputate sapien nec sagittis aliquam. Vestibulum mattis ullamcorper velit sed ullamcorper morbi. Donec adipiscing tristique risus nec.\n\nMattis vulputate enim nulla aliquet. Ante metus dictum at tempor commodo. Aenean euismod elementum nisi quis eleifend. Magna ac placerat vestibulum lectus mauris ultrices eros in. Porttitor lacus luctus accumsan tortor posuere ac. Diam volutpat commodo sed egestas egestas fringilla phasellus faucibus. Mattis nunc sed blandit libero volutpat sed cras ornare. Adipiscing vitae proin sagittis nisl rhoncus.")
                .font(.system(size: 13))
                .lineSpacing(8)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(.horizontal, 35.0)
            .navigationBarTitle(Text("About"), displayMode: .inline)
            .padding(.top, 45)
    }
    }
}

struct TermsView: View {
    var body: some View {
        ScrollView{
        VStack {
            Text("Terms & Conditions")
                .bold()
                .font(.system(size: 20))
                .padding(.bottom, 25)
                .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Diam phasellus vestibulum lorem sed risus ultricies tristique nulla. Sit amet tellus cras adipiscing. Suspendisse ultrices gravida dictum fusce ut placerat orci nulla. Interdum consectetur libero id faucibus. Libero id faucibus nisl tincidunt eget nullam. A arcu cursus vitae congue mauris rhoncus. Augue neque gravida in fermentum et. Interdum varius sit amet mattis vulputate. Gravida rutrum quisque non tellus orci ac auctor augue. Faucibus scelerisque eleifend donec pretium vulputate sapien nec sagittis aliquam. Vestibulum mattis ullamcorper velit sed ullamcorper morbi. Donec adipiscing tristique risus nec.\n\nMattis vulputate enim nulla aliquet. Ante metus dictum at tempor commodo. Aenean euismod elementum nisi quis eleifend. Magna ac placerat vestibulum lectus mauris ultrices eros in. Porttitor lacus luctus accumsan tortor posuere ac. Diam volutpat commodo sed egestas egestas fringilla phasellus faucibus. Mattis nunc sed blandit libero volutpat sed cras ornare. Adipiscing vitae proin sagittis nisl rhoncus.")
                .font(.system(size: 13))
                .lineSpacing(8)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(.horizontal, 35.0)
            .navigationBarTitle(Text("Terms & Conditions"), displayMode: .inline)
            .padding(.top, 45)
    }
    }
}

struct Content: View {
    
    @Binding var userEmail: String
    @Binding var userPassword: String
    @Binding var template: String
    @Binding var state: Bool
    @Binding var vol: Double
    
    var body: some View {
        LoginPage(userEmail: $userEmail, userPassword: $userPassword, template: $template, state: $state, vol: $vol)
    }
}

struct ConnectDevice: View {
    
    var action: () -> Void
    
    @State var color = Color.blue
    @State var radius = CGFloat(110)
    @State var painted = CGFloat(6)
    @State var unpainted = CGFloat(6)
    
    let count: CGFloat = 30
    let relativeDashLength: CGFloat = 0.25
    
    var body: some View {
        ZStack{
            Text("Connect a Device")
                .fontWeight(.bold)
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding()
                .frame(width: 300, height: 200)
                .background(
                Circle()
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round, dash: [painted, unpainted]))
                  .frame(width: radius * 2, height: radius * 2)
                  .onAppear {
                      let dashLength = CGFloat(2 * .pi * radius) / count
                      painted = 0.05*dashLength * relativeDashLength
                      unpainted = 2*dashLength * (1 - relativeDashLength)
                  }
                )
        }.contentShape(Circle())
            .gesture(
             TapGesture()
               .onEnded {
                 print("Hello world")
                 self.action()
             }
        )
    }
}

struct Configure: View {
    
    @Binding var name: String
    
    @Binding var userEmail: String
    @Binding var userPassword: String
    @Binding var template: String
    @Binding var state: Bool
    @Binding var vol: Double
    
    func click() -> Void {
        print("Hello")
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10){
                Image("bolt")
                    .resizable()
                    .frame(width: 15.0, height: 28.0)
                Text("SonicVision")
                        .fontWeight(.bold)
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0/255, green: 98/255, blue: 204/255))
                Spacer()
            }
            .frame(width: .infinity)
            Text("Welcome **\(name)**, mel ea numquam efficiendi appellantur, eu vix reque inermis propriae, animal scaevola.")
                .padding(.top, 35.0)
                .font(.system(size: 15))
                .foregroundColor(Color.gray)
                .padding(.bottom, 80)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .padding(.leading, -15)
            
            ConnectDevice(action: click)
            
            VStack {
                NavigationLink(destination: Settings(volume: $vol, voiceover: $state)) {
                    HStack(spacing: 5) {
                        Text("Configure Settings")
                            .fontWeight(.bold)
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0/255, green: 110/255, blue: 230/255))
                            .frame(alignment: .leading)
                        Image(systemName: "chevron.right").imageScale(.large).font(Font.system(.footnote).weight(.semibold))
                        Spacer()
                    }
                }
                .padding(.top, 70)
                .frame(width: .infinity, alignment: .leading)
                .padding(.bottom, 30)
                
                NavigationLink(destination: AboutView()) {
                    Text("About")
                        .fontWeight(.bold)
                        .font(.system(size: 15))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                }.padding(.bottom, 10)
                NavigationLink(destination: TermsView()) {
                    Text("Terms & Conditions")
                        .fontWeight(.bold)
                        .font(.system(size: 15))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                }
            }.padding(.bottom, 70)
            
            NavigationLink(destination: LoginPage(userEmail: $userEmail, userPassword: $userPassword, template: $template, state: $state, vol: $vol)) {
                Button(action: {
                    print("Sign Out clicked")
                }) {
                    Text("Sign Out")
                        .bold()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 15))
                                .padding(.all, 8)
                                .foregroundColor(Color(red: 0/255, green: 110/255, blue: 230/255))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0/255, green: 110/255, blue: 230/255), lineWidth: 1)
                            )
                    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                }.padding(.all, 5).frame(width: 105, alignment: .center)
        }
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(.horizontal, 35.0).padding(.top, -50).navigationBarBackButtonHidden(true)
    }
}

struct Settings: View {
    
    @Binding var volume: Double
    @Binding var voiceover: Bool
    
    var body: some View {
        ScrollView {
        VStack {
            VStack {
                HStack {
                    Text("System Volume")
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                }.padding(.bottom, 35)
                Slider(value: $volume, in: 0...100)
            }.padding(.bottom, 50)
            
            VStack {
                HStack {
                    Text("General Settings")
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                }.padding(.bottom, 20)
                
                HStack {
                    Toggle(isOn: $voiceover) {
                        Text("Enable VoiceOver Assistant")
                            .font(.system(size: 12))
                            .foregroundColor(Color.black)
                            .frame(alignment: .leading)
                    }.toggleStyle(SwitchToggleStyle(tint: .blue))
                        .onTapGesture {
                            print("toggle")
                        }
                }.padding(.bottom, 15)
                
                HStack {
                    Text("Language")
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                    Menu {
                        Text("Language 1")
                        Text("Language 2")
                        Text("Language 3")
                    }label: {
                        Text("Language").foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                            .font(.system(size: 10)).padding(.trailing, 40)
                        Image(systemName: "chevron.down").imageScale(.small).font(Font.system(.footnote).weight(.semibold)).foregroundColor(.black)
                    }.padding(.vertical, 5).padding(.horizontal, 10)
                        .background(.white)
                        .cornerRadius(8)
                        .shadow(color: .gray, radius: 8, x: 0, y: 3)
                }
            }.padding(.bottom, 50)
                
            VStack {
                HStack {
                    Text("General Settings")
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                }.padding(.bottom, 20)
                
                HStack {
                    Toggle(isOn: $voiceover) {
                        Text("Distance Notifications Enabled")
                            .font(.system(size: 12))
                            .foregroundColor(Color.black)
                            .frame(alignment: .leading)
                    }.toggleStyle(SwitchToggleStyle(tint: .blue))
                        .onTapGesture {
                            print("toggle")
                        }
                }.padding(.bottom, 15)
                HStack {
                    Toggle(isOn: $voiceover) {
                        Text("Sensor Notifications Enabled")
                            .font(.system(size: 12))
                            .foregroundColor(Color.black)
                            .frame(alignment: .leading)
                    }.toggleStyle(SwitchToggleStyle(tint: .blue))
                        .onTapGesture {
                            print("toggle")
                        }
                }.padding(.bottom, 15)
                HStack {
                    Toggle(isOn: $voiceover) {
                        Text("Camera Notifications Enabled")
                            .font(.system(size: 12))
                            .foregroundColor(Color.black)
                            .frame(alignment: .leading)
                    }.toggleStyle(SwitchToggleStyle(tint: .blue))
                        .onTapGesture {
                            print("toggle")
                        }
                }
            }.padding(.bottom, 50)
                
            VStack {
                HStack {
                    Text("Assistant Configurations")
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                }.padding(.bottom, 20)
                
                HStack {
                    Text("Assistant Language")
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                    Menu {
                        Text("Language 1")
                        Text("Language 2")
                        Text("Language 3")
                    }label: {
                        Text("Language").foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                            .font(.system(size: 10)).padding(.trailing, 40)
                        Image(systemName: "chevron.down").imageScale(.small).font(Font.system(.footnote).weight(.semibold)).foregroundColor(.black)
                    }.padding(.vertical, 5).padding(.horizontal, 10)
                        .background(.white)
                        .cornerRadius(8)
                        .shadow(color: .gray, radius: 8, x: 0, y: 3)
                }.padding(.bottom, 15)
                
                HStack {
                    Text("Assistant Voice")
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                    Menu {
                        Text("Voice 1")
                        Text("Voice 2")
                        Text("Voice 3")
                    }label: {
                        Text("Voice").foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                            .font(.system(size: 10)).padding(.trailing, 40)
                        Image(systemName: "chevron.down").imageScale(.small).font(Font.system(.footnote).weight(.semibold)).foregroundColor(.black)
                    }.padding(.vertical, 5).padding(.horizontal, 10)
                        .background(.white)
                        .cornerRadius(8)
                        .shadow(color: .gray, radius: 8, x: 0, y: 3)
                }.padding(.bottom, 15)
                
                HStack {
                    Text("Assistant Volume")
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                    HStack {
                        Button(action: {
                          print("volume minus pressed")

                        }) {
                            Image(systemName: "minus").imageScale(.small).foregroundColor(.black)
                        }
                        TextField("0", value: $volume, format: .number)
                            .padding(.vertical, 5).padding(.horizontal, 15)
                                .background(.white)
                                .cornerRadius(8)
                                .shadow(color: .gray, radius: 8, x: 0, y: 3)
                                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                                    .font(.system(size: 10))
                                    .fixedSize()
                        Button(action: {
                          print("volume minus pressed")

                        }) {
                            Image(systemName: "plus").imageScale(.small).foregroundColor(.black)
                        }
                    }
                }
            }.padding(.bottom, 50)
            
            VStack {
                HStack {
                    Text("Object Distance Configurations")
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                }.padding(.bottom, 20)
                
                HStack {
                    Text("Object Near Collision Alert")
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                    Menu {
                        Text("Sound 1")
                        Text("Sound 2")
                        Text("Sound 3")
                    }label: {
                        Text("Sound").foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                            .font(.system(size: 10)).padding(.trailing, 30)
                        Image(systemName: "chevron.down").imageScale(.small).font(Font.system(.footnote).weight(.semibold)).foregroundColor(.black)
                    }.padding(.vertical, 5).padding(.horizontal, 10)
                        .background(.white)
                        .cornerRadius(8)
                        .shadow(color: .gray, radius: 8, x: 0, y: 3)
                }.padding(.bottom, 15)
                
                HStack {
                    Text("Minimum Object Distance")
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                    TextField("0", value: $volume, format: .number)
                        .padding(.vertical, 5).padding(.horizontal, 10)
                            .background(.white)
                            .cornerRadius(8)
                            .shadow(color: .gray, radius: 8, x: 0, y: 3)
                            .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                                .font(.system(size: 10))
                                .fixedSize()
                    Text("meters(s)")
                        .font(.system(size: 10))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                }.padding(.bottom, 15)
            
                HStack {
                    Text("Customized Object Distance Sound")
                        .font(.system(size: 12))
                        .foregroundColor(Color.black)
                        .frame(alignment: .leading)
                    Spacer()
                    Menu {
                        Text("Sound 1")
                        Text("Sound 2")
                        Text("Sound 3")
                    }label: {
                        Text("Sound").foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                            .font(.system(size: 10)).padding(.trailing, 30)
                        Image(systemName: "chevron.down").imageScale(.small).font(Font.system(.footnote).weight(.semibold)).foregroundColor(.black)
                    }.padding(.vertical, 5).padding(.horizontal, 10)
                        .background(.white)
                        .cornerRadius(8)
                        .shadow(color: .gray, radius: 8, x: 0, y: 3)
                }
                
                Link(destination: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=URL@*/URL(string: "https://www.apple.com")!/*@END_MENU_TOKEN@*/) {
                    Text("Add new customized sound")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0/255, green: 110/255, blue: 230/255))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 20)
                .padding(.bottom, 105)
            }.padding(.bottom, 50)
            }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(.horizontal, 35).padding(.top, 50)
                .navigationBarTitle(Text("Settings"), displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    @State static var input = "Jerin"
    @State static var fields = ""
    @State static var number = 50.0
    @State static var check = true
    
    static var previews: some View {
//        Settings(volume: $input, voiceover: $check)
//        Content()
        LoginPage(userEmail: $fields, userPassword: $fields, template: $input, state: $check, vol: $number)
    }
}


