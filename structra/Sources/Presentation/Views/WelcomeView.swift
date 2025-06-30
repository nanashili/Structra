//
//  WelcomeView.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var projectVM: ProjectListViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("Welcome to DocEditor")
                .font(.largeTitle)
                .padding(.bottom, 20)

            HStack(spacing: 80) {
                Button(action: projectVM.createNewProject) {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        Text("New Project")
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: projectVM.openExistingProject) {
                    VStack(spacing: 8) {
                        Image(systemName: "folder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        Text("Open Project")
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

            if !projectVM.recentProjects.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Projects")
                        .font(.headline)
                    ForEach(projectVM.recentProjects) { proj in
                        Button {
                            Task { @MainActor in
                                do {
                                    let opened =
                                        try await projectVM.projectService
                                        .openProject(at: proj.url)
                                    projectVM.currentProject = opened
                                } catch {
                                    print(
                                        "Failed to open recent project:",
                                        error
                                    )
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(proj.name)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 40)
                .frame(maxWidth: 400)
            }

            Spacer()
        }
        .padding(50)
    }
}
