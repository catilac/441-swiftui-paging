import SwiftUI
import UIKit

struct PageNumber: ExpressibleByIntegerLiteral, Comparable {
    static func < (lhs: PageNumber, rhs: PageNumber) -> Bool {
        lhs.value < rhs.value
    }

    init(integerLiteral value: Int) {
        self.value = value
        self.previousValue = value
    }

    var value: Int {
        willSet {
            previousValue = value
        }
    }

    var previousValue: Int
}

@propertyWrapper
struct StorePrevious<Value> {
    var wrappedValue: Value {
        willSet {
            self.previousValue = wrappedValue
        }
    }

    var value: Value { wrappedValue }

    var previousValue: Value

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        self.previousValue = wrappedValue
    }
}

struct PageViewController: UIViewControllerRepresentable {
    var controllers: [UIViewController]
    @Binding var currentPage: StorePrevious<Int>

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(transitionStyle: .scroll,
                                          navigationOrientation: .horizontal)
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator

        return pageVC
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        let direction: UIPageViewController.NavigationDirection = currentPage.value >= currentPage.previousValue ? .forward : .reverse
        pageViewController.setViewControllers([controllers[currentPage.value]],
                                              direction: direction,
                                              animated: true,
                                              completion: nil)
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: PageViewController

        init(_ parent: PageViewController) {
            self.parent = parent
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = parent.controllers.firstIndex(of: viewController) else { return nil }

            if index == 0 {
                return nil // or parent.controllers.last
            }

            return parent.controllers[index - 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = parent.controllers.firstIndex(of: viewController) else { return nil }

            if index == parent.controllers.endIndex - 1 {
                return nil // or parent.controllers.first
            }

            return parent.controllers[index + 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
                let visibleViewController = pageViewController.viewControllers?.first,
                let index = parent.controllers.firstIndex(of: visibleViewController) {

                parent.currentPage.wrappedValue = index
            }

        }
    }
}

struct PageView<Page: View>: View {

    let controllers: [UIHostingController<Page>]
    @Binding var currentPage: StorePrevious<Int>

    init(_ pages: [Page], currentPage: Binding<StorePrevious<Int>>) {
        controllers = pages.map { UIHostingController(rootView: $0) }
        self._currentPage = currentPage
    }

    var body: some View {
        VStack {
            PageViewController(controllers: controllers, currentPage: $currentPage)
                .id(UUID())
        }
    }
}


struct ContentView: View {

    @State @StorePrevious var currentPage: Int = 0

    let cards: [Card] = [
        Card(title: "Blue", color: .blue),
        Card(title: "Red", color: .red),
        Card(title: "Green", color: .green),
        Card(title: "Pink", color: .pink),
        Card(title: "Purple", color: .purple),
        Card(title: "Orange", color: .orange)
    ]

    var body: some View {

        VStack {
            PageView(cards, currentPage: $currentPage)
                .aspectRatio(4/3, contentMode: .fit)

            HStack {
                Button(action: {
                    if self.currentPage > 0 {
                        self.currentPage -= 1
                    }
                }) {
                    Image(systemName: "arrow.left")
                }
                .disabled(self.currentPage == 0)
                Text("Current Page: \(self.currentPage)")
                Button(action: {
                    if self.currentPage < self.cards.count - 1 {
                        self.currentPage += 1
                    }
                }) {
                    Image(systemName: "arrow.right")
                }
                .disabled(self.currentPage == self.cards.count - 1)
            }

            Button(action: {
                self.currentPage = 3
            }) {
                Text("Go to page 3")
            }
        }
    }
}

struct Card: View {
    let title: String
    let color: Color

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle().fill(color)

            Text(title).font(.largeTitle).foregroundColor(.white)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
