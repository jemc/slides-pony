
![LFNW-start](http://i.imgur.com/oAfZSvL.png)

---

![Pony](img/horse.png)

# Pony
## An Actor Language For
### Provably Safe Lockless Concurrency

---

## Who Am I?

![jemc](img/jemc.png) ![cb](img/cb.png)

### Joe Eli McIlvain - Citrusbyte

https://github.com/jemc - https://citrusbyte.com

These slides on GitHub: https://github.com/jemc/slides-pony

---

## Concurrency

### What is it?
### Why do we want it?
### Why do we fear it?

----

## Concurrency

### What is it?

Multiple tasks executed in a disjoint, overlapping way

Can be in *parallel* and/or *scheduled*

Relative order of execution is unknown

----

## Concurrency

### Why do we want it?

Concurrency alone isn't enough, but...

Running our code in *parallel* can give us:

* scalability

* efficiency

----

## Concurrency

### Why do we fear it?

Non-determinism in the order of events

Can lead to subtle bugs:

* data race

* non-atomicity

* deadlock

----

## Concurrency

### So how do we stay sane?

Embrace a structured approach

---

## Synchronization

> Wherever my tasks share state with eachother, I can synchronize access to that state appropriately to avoid concurrency bugs.

----

## Synchronization

### How does it help?

Use locks to restrict the relative order of events

Blocks the task instead of violating the restriction

----

## Synchronization

### Reduces Concurrency

Synchronized operations become non-concurrent

More synchronization => less concurrency

More synchronization => more waiting

----

## Synchronization

### is Error Prone

Lose as little concurrency as possible by being precise

More precise synchronization => more cognitive complexity

Mo' concurrency => mo' problems

---

## Share Nothing

> If my tasks share no state with eachother, then safe concurrency is trivial.

----

## Share Nothing

### Why is it safe?

We get bugs when we share state,

So let's not share any state.

* no interdependence

* no communication

----

## Share Nothing

### Advantages

* always safe
* easy to reason about
* easy to migrate between distinct machines
* scales perfectly

----

## Share Nothing

### Disadvantages

* only applies to tasks that can be made independent
* breaks as soon as you need to share something

---

## Share Immutable State

> If my tasks share only immutable state with eachother, then safe concurrency is trivial.

----

## Share Immutable State

### Why is it safe?

We get bugs when we share mutable state,

So let's not allow any mutation of it.

* immutable data structures

* frozen objects

----

## Share Immutable State

### Advantages

* always safe
* easy to reason about
* provides a way to share global data

----

## Share Immutable State

### Disadvantages

* can't migrate between distinct machines without copying data
* only applies to tasks that can be made otherwise independent
* breaks as soon as you need to share something mutable

---

## Transfer Isolated State

> If I can transfer exclusive access to a given state object from task to task, then the one task that can reach the state object at any given time may safely mutate it without violating concurrency safety.

----

## Transfer Isolated State

### Why is it safe?

We get bugs when we share mutable state,

So let's share it indirectly, *across time*.

* "thread ownership"

* "message passing"

----

## Transfer Isolated State

### Advantages

* easy to reason about
* no mutability restrictions
* compatible with zero-copy optimizations

----

## Transfer Isolated State

### Disadvantages

* state is not truly shared - no concurrent access
* requires careful discipline (or language support)

---

## So what should we choose?

* ### A. Synchronization
* ### B. Share Nothing
* ### C. Share Immutable State
* ### D. Transfer Isolated State

----

## All of the Above
### (Except Synchronization)

----

## So what do we want?

Easy to use the safe patterns

Verify safety by verifying the patterns

Clear and explicit - no guesswork

Clean, consistent syntax and rules

---

## Enter Pony
### A Language for Provably Safe
### Lockless Concurrency

http://www.ponylang.org/

https://github.com/ponylang/ponyc

----

## Enter Pony
### A Young Language

----

## Enter Pony
### A Static, Compiled Language

Static analysis enforces concurrency patterns

Understands your application without running it

Concurrency safety without cost of runtime checks

High performance

----

## Enter Pony
### A Type-Safe Language

Yeah, I know, `*`*groan*`*`

But concurrency safety makes it worthwhile

Some nice syntax sugar makes it "not so bad"

----

## Enter Pony
### An Object-Oriented Language

Functional programming languages are cool,

But objects are nice and natural abstractions

In Pony we can have them *and keep* many benefits of FP

And you can still use functions when it makes sense

----

## Enter Pony
### An Actor Language

Pass messages, trigger behaviours

Messages have causal order, not sequential order

Scheduled by the runtime

No synchronization primitives (lockless)

No blocking operations

---

## Pony Paradigms

----

## Pony Paradigms
### No Blocking!

Blocking is an anti-pattern

If we allowed blocking it would either:

* make our actor go idle when there is still more work for it to do

* make our actor behaviours non-atomic (and accumulate memory)

We choose never-idle, always atomic.

We choose to never make the asynchronous appear synchronous.

----

## Pony Paradigms
### Causality

----

## Pony Paradigms
### Causality

Forget total order, embrace causal order

<code>
```ruby
.     (events over time)     .
<-- A ---- B ---- C ---- D -->
```
</code>

----

## Pony Paradigms
### Causality

Forget total order, embrace causal order

<code>
```ruby
<---- A --------------------->
.                            .
<--------------------- B ---->
.                            .
<---------------- C --------->
.                            .
<-- D ----------------------->
```
</code>

----

## Pony Paradigms
### Causality

Effects follow causes

<code>
```ruby
<---- A --------------------->
.      \                     .
<------ B ------------------->
.                            .
<---------------- C --------->
.                  \         .
<------------------ D ------->
```
</code>

----

## Pony Paradigms
### Causality

Forked message passing causality

<code>
```ruby
<-- A1***A2 ----------------->
.    \    \                  .
<---- LA - \ ----- LB ------->
.           \     /          .
<---------- B1***B2 --------->
```
</code>

----

## Pony Paradigms
### Causality

Forked message passing causality, breaks down

<code>
```ruby
<-- A1***A2 ----------------->
.    ^~~~~\~~~~~~~~~~~~~~,   .
<--------- \ ----- LB -- LA ->
.           \     /          .
<---------- B1***B2 --------->
```
</code>

----

## Pony Paradigms
### Causality

Single chain of message passing, but weird code

<code>
```ruby
<------- A2 ---------------->
.         \                 .
<-------- LA --- LB -------->
.          \     /          .
<--------- B1***B2 --------->
```
</code>

----

## Pony Paradigms
### Causality

Forked message passing causality, enforced in Pony

<code>
```ruby
<-- A1***A2 ----------------->
.    \    \                  .
<---- LA - \ ----- LB ------->
.           \     /          .
<---------- B1***B2 --------->
```
</code>

----

## Pony Paradigms
### Capability Security

Unforgeable tokens of authority

Authority is inherently decentralized

Principle of least privilege

Tokens are revocable

----

## Pony Paradigms
### Capability Security

Object references as capabilities

Object references are unforgable

Object references can be attenuated

---

## Pony Concepts

----

## Pony Concepts
### Basic syntax

```pony
class Person
  var name: String = "John Doe"
  var age:  U8     = 0
 
  fun greeting(): String =>
    "Hello, " + name
 
  fun age_diff(that: Person): U8 =>
    if age > that.age
    then age - that.age
    else that.age - age
    end
```

----

## Pony Concepts
### References

```pony
let a = Person // create a new Person and refer to it as a
let b = Person // create another Person and refer to it as b
var c = Person // a, b, and c refer to three unique Persons
c = a          // c is now an alias of a
b = a          // COMPILER ERROR - can't reassign a let reference
```

----

## Pony Concepts
### Introducing Reference Capabilities

| Safe Concurrency Pattern | Ref. Cap. |
|--------------------------|-----------|
| Share Nothing            | `tag`     |
| Share Immutable State    | `val`     |
| Transfer Isolated State  | `iso`     |

----

## Pony Concepts
### Reference Capabilities Table

| Ref. Cap. | Hint       | This reference | Other references | Sendable? |
|-----------|------------|----------------|------------------|-----------|
|`ref`      | Mutable    | read/write     | read/write       | no        |
|`val`      | Immutable  | read           | read             | yes       |
|`box`      | Read-only  | read           | read/write       | no        |
|`iso`      | R/W-unique | read/write     | no access        | yes       |
|`trn`      | W-unique   | read/write     | read             | no        |
|`tag`      | Opaque     | no access      | no access        | yes       |

----

## Pony Concepts
### Implicit Reference Capabilities

```pony
class Person
  var name: String = "John Doe"
  var age:  U8     = 0
 
  fun age_diff(that: Person): U8 =>
    if age > that.age
    then age - that.age
    else that.age - age
    end
```

```pony
class ref Person
  var name: String val = "John Doe"
  var age:  U8 val     = 0
 
  fun box age_diff(that: Person ref): U8 val =>
    if age > that.age
    then age - that.age
    else that.age - age
    end
```

----

## Pony Concepts
### Reference Capabilities Summary

There's more to see, but not today `*`*wink*`*`

There's a learning curve, but it's worth it!

Ref caps bring explicit structure to lockless concurrency

Ref caps have no runtime cost!

---

# Questions?

---

![LFNW-finish](http://i.imgur.com/9eAtxdp.png)
