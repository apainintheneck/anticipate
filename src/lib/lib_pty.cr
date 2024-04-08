# In reality, this could be shoved into LibC as well but
# I just didn't want to pollute that namespace.
lib LibPTY
  alias Char = LibC::Char
  alias Int = LibC::Int

  fun posix_openpt = posix_openpt(flags : Int) : Int
  fun grantpt = grantpt(fd : Int) : Int
  fun unlockpt = unlockpt(fd : Int) : Int
  fun ptsname = ptsname(fd : Int) : Char*
end
