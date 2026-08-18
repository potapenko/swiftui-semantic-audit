import SwiftUI

struct CrossFeatureLeaf: View {
    let other: OtherModel
    var body: some View { Text("\(other.value)") }
}
