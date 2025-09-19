if [[ -t 0 && $- = *i* ]]
then
  stty stop undef
  stty start undef
fi
