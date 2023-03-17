{10.emit}"cr".def   # new line
{32.emit}"sp".def   # space
{over over} "dup2" .def
{swap drop} "nip" .def
{swap _ins_f1 .exec} ".dip" .def      # a b {some} .dip --> a some b
{over _ins_f1 .exec} ".sip" .def      # a b {some} .sip --> a b some b


