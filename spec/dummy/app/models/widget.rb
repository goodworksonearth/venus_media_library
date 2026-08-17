# Test-only host model. Exercises the gem's attach mode: a picked blob's
# signed_id is assigned to `cover` (a has_one_attached association) so Active
# Storage attaches it on save — exactly what media_attach_field wires up.
class Widget < ApplicationRecord
  has_one_attached :cover
end
