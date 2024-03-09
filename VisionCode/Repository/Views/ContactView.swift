//
//  ContactView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 3/8/24.
//

import Foundation
import SwiftUI

struct ContactView: View {
    var body: some View {
        VStack {
            Text("Welcome to VisionCode")
                .font(.largeTitle)
            ScrollView {
                VStack {
                    Text(visionCodeDescription)
                        .padding()
                    Spacer()
                    VStack {
                        Text("Contact")
                            .font(.title)
                        Image("developer")
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("Michael Crabtree")
                        HStack {
                            Button {
                                UIApplication.shared.open(emailURL)
                            } label: {
                                Label {
                                } icon: {
                                    Image(systemName: "mail")
                                        .foregroundColor(.black)
                                }
                            }
                            Button {
                                UIApplication.shared.open(githubURL)
                            } label: {
                                Label {
                                } icon: {
                                    Image("github").resizable()
                                        .frame(width: 25, height: 25)
                                    
                                }
                            }
                            Button {
                                UIApplication.shared.open(twitterURL)
                            } label: {
                                Label {
                                } icon: {
                                    Image("twitter").resizable()
                                        .frame(width: 27, height: 25)
                                }
                            }
                            Button {
                                UIApplication.shared.open(linkedinURL)
                            } label: {
                                Label {
                                } icon: {
                                    Image("linkedin").resizable()
                                        .frame(width: 25, height: 25)
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
}


let visionCodeDescription = """
VisionCode is an ambitious project to bring a full, native IDE to visionOS. The belief at the heart of VisionCode is that spatial computer allows for new ways of working in new places. As visionOS grows so too will the need for a full-featured IDE. That's why VisionCode is free forever and open source. It will require the contributions of lots of developers to make that possible.
                         
You are already helping. You are one of the first beta testers on VisionCode! Your feedback and experiences are extremely helpful to grow VisionCode. Please reach out through one of the various methods below.

If you would like access to the source code, check back here for updates regularly. I am working hard on getting the repositories set up for external contributions. You can expect them to be released towards the end of March. I will update this page when they are available.
"""

let emailURL = URL(string: "mailto:visioncode@macmail.app")!
let githubURL = URL(string: "https://github.com/crabtree-michael")!
let twitterURL = URL(string: "https://twitter.com/maccrabtree")!
let linkedinURL = URL(string: "https://www.linkedin.com/in/michael-crabtree-839b28126/")!


#Preview {
    ContactView()
}
