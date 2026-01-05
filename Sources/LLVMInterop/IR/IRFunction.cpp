#include "IRFunction.h"

optional<string> IRFunction::print() const {
  string string = "";
  raw_string_ostream stream(string);

  if (this->_isValid) {
    this->_f->print(stream);
    return string;
  } else {
    return nullopt;
  }
}

optional<string> IRFunction::verify() const {
  string string = "";
  raw_string_ostream stream(string);

  if (verifyFunction(*(this->_f), &stream)) {
    return string;
  } else {
    return nullopt;
  }
}
