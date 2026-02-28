
extension StringProtocol {
    func int<T: FixedWidthInteger>() -> T? {
        T(self) 
    }
}