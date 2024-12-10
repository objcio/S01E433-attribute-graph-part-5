import AttributeGraph
import SwiftUI

struct Sample: View {
    @State var snapshots: [GraphValue] = []
    @State var index: Int = 0

    var body: some View {
        VStack {
            if index >= 0, index < snapshots.count {
                Graphviz(dot: snapshots[index].dot)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Stepper(value: $index, label: {
                    Text("Step \(index + 1)/\(snapshots.count)")
                })
            }
        }
        .padding()
        .onAppear {
            snapshots = sample()
        }
    }
}

struct LayoutComputer {
    let sizeThatFits: (ProposedViewSize) -> CGSize
}

func sample() -> [GraphValue] {
    /*
     struct Nested: View {
     @State var toggle = false
     var body: some View {
         Color.blue.frame(width: toggle ? 50 : 100)
     }

     struct ContentView: View {
         var body: some View {
            HStack {
                Color.red
                Nested()
            }
         }
     }
     */

    let graph = AttributeGraph()
    let toggleStateProp = graph.input(name: "toggle", false)
    let inputSize = graph.input(name: "inputSize", CGSize(width: 200, height: 100))

    let redLayoutComputer = graph.rule(name: "red layoutComputer") {
        LayoutComputer { proposedSize in
            proposedSize.replacingUnspecifiedDimensions()
        }
    }

    let nestedLayoutComputer = graph.rule(name: "nested layoutComputer") {
        let toggleSP = toggleStateProp.wrappedValue
        return LayoutComputer { proposedSize in
            let width: CGFloat = toggleSP ? 50 : 100
            let height = proposedSize.height ?? 10
            return CGSize(width: width, height: height)
        }
    }
    
    let hstackLayoutComputer = graph.rule(name: "hstack layoutComputer") {
        let nestedLC = nestedLayoutComputer.wrappedValue
        let redLC = redLayoutComputer.wrappedValue
        return LayoutComputer(sizeThatFits: { proposal in
            var remainder = proposal.width! // todo
            let childProposal = CGSize(width: remainder/2, height: proposal.height!)
            let nestedSize = nestedLC.sizeThatFits(.init(childProposal))
            remainder -= nestedSize.width
            let childProposal2 = CGSize(width: remainder, height: proposal.height!)
            let redResult = redLC.sizeThatFits(.init(childProposal2))
            let result = CGSize(width: redResult.width + nestedSize.width, height: max(redResult.height, nestedSize.height))
            return result
        })
    }

    let hstackSize = graph.rule(name: "hstack size") {
        return hstackLayoutComputer.wrappedValue.sizeThatFits(.init(inputSize.wrappedValue))
    }

    var result: [GraphValue] = []
    result.append(graph.snapshot())

    let _ = hstackSize.wrappedValue
    result.append(graph.snapshot())

    toggleStateProp.wrappedValue.toggle()
    result.append(graph.snapshot())

    let _ = hstackSize.wrappedValue
    result.append(graph.snapshot())

    inputSize.wrappedValue.width = 300
    result.append(graph.snapshot())

    let _ = hstackSize.wrappedValue
    result.append(graph.snapshot())

    return result
}
