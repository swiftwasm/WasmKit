is_amazonlinux2() {
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "$ID" == "amzn" ]; then
      return 0
    fi
  fi
  return 1
}

is_debian_family() {
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "$ID_LIKE" == "debian" ]; then
      return 0
    fi
  fi
  return 1
}
