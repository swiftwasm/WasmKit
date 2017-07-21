protocol CharacterStream {
	func look() -> String.UTF8View.Element?
	func consume()
}

class StringStream: CharacterStream {

	let characters: String.UTF8View
	var index: String.UTF8View.Index

	init(string: String) {
		characters = string.utf8
		index = characters.startIndex
	}

	func look() -> String.UTF8View.Element? {
		guard characters.indices.contains(index) else {
			return nil
		}
		return characters[index]
	}

	func consume() {
		index = characters.index(after: index)
	}

}
