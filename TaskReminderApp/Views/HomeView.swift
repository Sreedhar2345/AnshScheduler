import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            ThemeBackgroundView(
                theme: store.selectedTheme,
                personalBackgroundData: store.personalBackgroundData
            )

            List {
                ForEach(store.tasks) { task in
                    HStack(spacing: 12) {
                        if let imageData = task.imageData,
                           let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.35))
                                .frame(width: 48, height: 48)
                                .overlay(Image(systemName: "checklist"))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.name)
                                .font(.headline)
                            Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.black.opacity(0.18))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Tasks")
    }
}
