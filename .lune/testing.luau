--!strict
-- Types for the Lune test suites: a suite is function(test, expect).

local expect = require("./expect")

export type Expect = typeof(expect)
export type Test = (name: string, body: () -> ()) -> ()
export type Suite = (test: Test, expect: Expect) -> ()

return {}
