import Foundation

enum ReminderTimesCodec {
    static func encode(_ times: [ReminderTime]) -> String? {
        let value = times.sorted().map(\.clockLabel).joined(separator: "|")
        return value.isEmpty ? nil : value
    }

    static func decode(_ raw: String?) -> [ReminderTime] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.split(separator: "|").compactMap { value in
            let parts = value.split(separator: ":")
            guard parts.count == 2,
                  let hour = Int(parts[0]),
                  let minute = Int(parts[1]) else {
                return nil
            }
            return ReminderTime(hour: hour, minute: minute)
        }
        .sorted()
    }
}
