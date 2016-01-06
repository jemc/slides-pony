
![Pony](img/horse.png)

# Pony
## An Actor Language For
### Provably Safe Lock-Free Concurrency

---

## Concurrency

### What is it?
### Why do we want it?
### Why do we fear it?

----

## Concurrency

### What is it?

%% So, what is concurrency?

%% Concurrency is having multiple tasks that are being executed in a disjoint, overlapping way.

Multiple tasks executed in a disjoint, overlapping way

%% Note that these tasks can be executed in *parallel* on multiple processors at once *and/or* *scheduled* into arbitrary slices of time on one or more processors.

Can be in *parallel* and/or *scheduled*

%% When we're talking about concurrency, we just mean that we're not sure when each task is running relative to any other - they could be running in parallel, or they could be running in some unknown, possibly interleaved sequence.

Relative order of execution is unknown

%% We just don't know, and concurrent code is code that operates under this paradigm of not knowing this.

%% To be clear, each *task* is a linear sequence of operations with a well-defined order, but the *timing* of the operations in a task *relative* to those in the *other* concurrent tasks is arbitrary and undefined.

----

## Concurrency

### Why do we want it?

%% So, why do we want concurrency?

%% Well, it turns out that just prepping our application for concurrency isn't enough to get any *direct* benefits, though as we discussed, it allows our code to be run in a *parallel and/or scheduled* way, and *that* in turn can give us some very important benefits:

Concurrency alone isn't enough, but...

Running our code in *parallel* can give us:

* scalability %% We want to be able to add more processors to get proportionally more throughput - that's scalability.

* efficiency %% We don't want to have any idle processors, as that would be inefficient - we want to put all of our processors to work for efficiency.

----

## Concurrency

### Why do we fear it?

%% So, why do we fear concurrency? - what's the problem?

Non-determinism in the order of events

%% Essentially, with concurrency, we want to be able to write application where we don't know the order in which everything is happening, but we can be sure that the final result is always correct.

%% This may sound a bit difficult, because it is. Arbitrary relative timings are a type of *nondeterminism*, and we want our overall application to be *deterministic*.

%% Now, we can easily allow order-nondeterminism where it doesn't matter. For example, if I ask you to go get groceries, clean the bathroom, and finish painting the shed, I probably don't care what order you do those things in, as long as they each get done.

%% However, if I ask you to go get groceries, deposit the paycheck, and pay the rent, the order in which you do these things might matter a great deal, depending on how much money is in our checking account.

%% Depending on how we structure our code and our concepts, the order-nondeterminism of concurrency can lead to subtle bugs that are difficult to reason about, reproduce, and test for. Here are some broad categories of concurrency bugs that we encounter:

Can lead to subtle bugs:

* data race %% one or more tasks access the same data in an undefined order, where one or more order possibilities leads to incorrect behavior.

* non-atomicity %% a conceptually atomic operation in one task is interrupted by another task, where the "middle" state that was not considered by the programmer leads to incorrect behavior in other tasks.

* deadlock %% interdependent tasks that are *blocking* (that is, waiting) for data or signal from eachother are mutually unable to make progress.

----

## Concurrency

### So how do we stay sane?

%% Given that we want concurrency, but dealing with concurrency can bring about these problems, how do we go about creating concurrent applications that we can be confident about?

Embrace a structured approach

%% Well, we need to embrace a structured approach to concurrency, where that structure brings some sanity and reason back to the jumble of nondeterminism that we'd otherwise be faced with.

%% So let's take a look at some of the structured approaches and conventions that we see out there...

---

## Synchronization

> Wherever my tasks share state with eachother, I can synchronize access to that state appropriately to avoid concurrency bugs.

----

## Synchronization

### How does it help?

%% So, how does it help?

Use locks to restrict the relative order of events

%% Using synchronization primitives like locks, mutexes, monitors, and semaphores allows the programmer to impose *restrictions* on the relative order of *specific groups* of operations within concurrent tasks.

Blocks the task instead of violating the restriction

%% Effectively, these primitives force the tasks to *wait* (or *block*) for availability where they would otherwise plunge ahead and violate the given restrictions.

%% If planned appropriately and effectively, these restrictions can prevent the kinds of concurrency bugs we highlighted.

%% However, let's take another look at what synchronization is actually doing to our applications.

----

## Synchronization

### Reduces Concurrency

%% Synchronization *reduces* concurrency

Synchronized operations become non-concurrent

%% We've said that synchronization primitives allow the programmer to impose *restrictions* on the order of specific groups of operations, and we've also said that *concurrency* is the paradigm of not knowing the order of operations.

%% So, we see that synchronization works by allowing us to selectively *prevent concurrency* of certain operations.

%%As an extreme example, note that if we use a common mutex to synchronize the entire block of code for each concurrent task - so they're all using the same single global lock, and the entire tasks are synchronized - effectively, at this point there is no concurrency left at all - the mutex will force our tasks to be run sequentially instead of concurrently.

%% Now, that was indeed an extreme and contrived example, but we can see that in less extreme cases, it behaves the same way - the more synchronization we introduce in our tasks the more they end up waiting around, and the more we *reduce the degree of effective concurrency*

More synchronization => less concurrency

%% In this way, synchronization is more of a *workaround* for concurrency than a safe pattern of concurrency, and the more we use synchronization the more we will lose the benefits concurrency gives us

%% A familiar example of over-synchronization is the Global Interpreter Lock found in the reference implementation of Ruby, in which almost all of the operations of the interpreter are synchronized by a single global lock, which severely reduces the actual concurrency that is possible using Ruby Threads - in fact, it shows us that our earlier extreme example isn't all that contrived after all - it's worth noting that the competing Ruby implementations, Rubinius and JRuby, improve on this strategy by using many fine-grained locks instead of one single global lock

----

## Synchronization

### is Error Prone

Lose as little concurrency as possible by being precise

%% So, to avoid losing too much concurrency to over-synchronization, we want to use synchronization primitives in a precise, detail-oriented way - synchronizing as little as possible to be safe

More precise synchronization => more cognitive complexity

%% However, the more precisely we use synchronization, the more difficult it becomes to reason about possible outcomes and the more likely we are to cause or fail to prevent concurrency bugs

Mo' concurrency => mo' problems

%% Regrettably, using synchronization with concurrency creates a situation where the more performance-optimal our code becomes, the more difficult it becomes to understand and maintain

%% This is a terrible tradeoff, and grappling with it in this way is one of the main reasons why we're all afraid of concurrency 

%% So let's move on to another approach:

---

## Share Nothing

> If my tasks share no state with eachother, then safe concurrency is trivial.

----

## Share Nothing

### Why is it safe?

%% So why is it safe?

We get bugs when we share state,

So let's not share any state.

%% Well, The concurrency bugs we highlighted were all related to the interdependence of concurrent tasks - put another way, we get problems when we share state between tasks

%% So, if we want to avoid the problems associated with synchronizing access to shared state, one trivial remedy is to avoid shared state altogether

%% And indeed, when you can pull it off, this works *beautifully* - it scales perfectly because there is no relationship at all between the tasks, so there's no possibility of a bottleneck as you scale

* no interdependence

* no communication

%% If our concurrent tasks are truly independent from one another, the nondeterminism of relative timings doesn't matter - that is, every possible order of events is correct behavior, because the tasks don't care about eachother at all

----

## Share Nothing

### Examples

* multiple tasks as concurrent UNIX processes, each with a separate input and output stream

* multiple tasks as concurrent POSIX threads in C, each with no access to any global or static state

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

%% With some more consideration, we see it's not quite necessary to prohibit all sharing - rather it's sufficient to make sure that anything we do share is immutable - that is, guaranteed to never change

%% If the data in the shared state is guaranteed to never change, then any task can read from it at any time and always see the same data

%% There's no need to synchronize because a read operation will have never have any influence over the outcome of any other read operations

* immutable data structures

* frozen objects

%% These nice properties - as well as others - make immutable data structures a popular choice for shared data - as long as it's immutable, there are no concurrency bugs to worry about

----

## Share Immutable State

### Examples

* multiple tasks as concurrent UNIX processes, each with a separate input and output stream as well as access to a read-only file system.

* multiple tasks as concurrent "processes" in a single Erlang VM, with shared access to some immutable data structures.

----

## Share Immutable State

### Advantages

* always safe
* easy to reason about
* provides a way to share global data %% giving in to the restriction that it can't be changed

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

%% Let's talk about what we mean when we say isolated - isolated state is only accessible from one task at a time, so is not concurrently shared

%% When tasks are implemented as threads, this is sometimes called *thread-ownership* - the state is held exclusively by a single thread, its owner - and no other thread it touch it

%% This is clearly safe, but without sharing, it doesn't solve the original problem

%% We can't share isolated state between multiple tasks at once, but we *can* share isolated state *across time* by securely transferring it from one task to another - this is sometimes called *message passing* or transferring thread ownership

* "thread ownership"

* "message passing"

%% When I say securely transferring, I mean this - if we can guarantee that the original task doesn't hold on to any dangling references to the transferred state object, then it is still isolated when it reaches the next task - but if even a single reference is retained in the original task - sometimes called a *leaked* reference - all safety goes out the window, because both tasks have access to the same mutable state object

%% So this method usually requires strict discipline to avoid leaking references, or language support to check and enforce that no references are leaked

----

## Transfer Isolated State

### Examples

* multiple tasks as concurrent CZMQ actors, passing struct pointers over `inproc` sockets (with careful discipline not to leak references).

* multiple tasks as concurrent Go-routines, passing objects over Go channels (with careful discipline not to leak references).

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

%% Each of these paradigms has its advantages and disadvantages, and they each have their place in our applications - so why should we have to choose?

%% However, remember that Synchronization was not a safe pattern for concurrency, but rather a way to reduce concurrency where we needed to.

%% We want to maximize concurrency, so let's leave Synchronization behind for now, and see if we can create our applications without it.

----

## So what do we want?

Easy to use the safe patterns

%% We want to use tools and conventions that make these safe patterns easy to use - programmers are lazy, so we have to make it easy to do the right thing or we'll mostly choose to do the wrong thing.

Verify safety by verifying the patterns

%% In fact, let's take it a step further and say that we never want to ship an application that isn't concurrency safe. If we *enforce* the safe patterns, then we can write highly concurrent applications while remaining fully confident in their safety.

Clear and explicit - no guesswork

%% Since we're mixing and matching the safe concurrency patterns, we also want to make it clear to eachother and to ourselves which patterns we are using for any given part of our code. For example, no human or tool that's reading our code should ever have to guess whether a given state object is intended to be *immutable* or *isolated*.

%% Explicit clarity of intent will keep our applications easy to reason about as their behaviour becomes more complex.

Clean, consistent syntax and rules

%% Furthermore, the way we show our intent should be ubiquitous and uniform, with a clean, consistent syntax, and simple rules for understanding what that syntax means.

---

## Enter Pony
### A Language for Provably Safe
### Lock-Free Concurrency

http://www.ponylang.org/

https://github.com/CausalityLtd/ponyc

----

## Enter Pony
### A Young Language

%% So, before we get too ahead of ourselves, I wanted to give a quick disclaimer.

%% Pony is an emerging technology - it's a young language that's changing every day - it's not ready for production, but it's also not theoretical - it's a real language with a real compiler and runtime, and it's ready to run real applications.

%% To me, this is a really exciting time to be involved with the language.

%% and the core developers - a handful of academic folks in Britain - have given it a really solid theoretical foundation - if you're as interested as I am, you can read the academic papers online to see how all of this works.

----

## Enter Pony
### A Static, Compiled Language

Static analysis enforces concurrency patterns

Understands your application without running it

%% Pony is a static, compiled language. The compiler is the tool that statically analyzes and enforces the safe concurrency patterns we've been talking about - static means that it doesn't have to run your code to understand it.

Concurrency safety without cost of runtime checks

%% If Pony were a dynamic language (as opposed to static), it would need to run your code before it understood it - This effectively means it would need to run your code surrounded by a bunch of runtime checks to ensure concurrency safety at every step of the way, effectively slowing down your code as well as making you add a bunch of guard code to "rescue" concurrency violation errors if they do happen.

%% Doing this analyis statically instead allows your application to only spend time only doing "business logic".

High performance

%% In terms of performance, Pony applications are comparable to some of the fastest compiled languages, like C.

----

## Enter Pony
### A Type-Safe Language

%% Type safety is also part of Pony's static analysis.

Yeah, I know, `*`*groan*`*`

%% Now, like most of you, I am totally comfortable writing robust code in "type-less" languages like Ruby and Javascript, and I often argue that type-safe languages usually create more hassle for the programmer than they solve.

But concurrency safety makes it worthwhile

%% However, in Pony, the concurrency patterns we've been talking about are *part of the type system*. This is a big deal because while it's pretty easy to intuitively understand and reason about what types of objects you're dealing with in each part of a well-written application, it can be much harder to understand and reason about how those objects might be accessed concurrently.

Some nice syntax sugar makes it "not so bad"

%% In this case, since we're already doing a lot of static analysis to ensure concurrency safety, I think it's reasonable and helpful to go for type safety as well, and Pony does a pretty good job of not making this too much of a headache for the programmer, with lots of syntax sugar.

----

## Enter Pony
### An Object-Oriented Language

%% Pony is object-oriented.

Functional programming languages are cool,

%% Now, as concurrency becomes more and more important in our applications, a lot of people are turning to functional languages to solve these problems we've been talking about - usually with a focus on immutable data structures.

But objects are nice and natural abstractions

%% Functionally pure languages can be quite satisfying to work with, but if you're like me, you start to miss the convenient abstraction of objects.

%% Functional languages eschew objects because they aren't referentially transparent, making it difficult to enforce safe patterns.

In Pony we can have them *and keep* many benefits of FP

%% However, in Pony, we can get the same benefits from objects because both the humans and the tools reading the code have complete information about how our object reference graphs are structured, including the restrictions of the concurrency patterns each part of the graph follows.

----

## Enter Pony
### An Actor Language

%% Pony is an actor language.

%% This means that instead of expressing concurrency in terms of explicit threads, fibers, processes, or co-routines, we use a higher-level abstraction called actors.

Pass messages, trigger behaviours

%% In short, we define actors that accept asynchronous messages that trigger a corresponding behaviour when a message is received.

%% We essentially get to define our program in terms of causes and effects, rather than strictly sequences of operations.

Scheduled by the runtime

%% We give these actor definitions to the Pony runtime, which handles their message passing and the scheduled executing of behaviours so we don't have to worry about any of those details.

No synchronization primitives (lock-free)

%% Because our actors follow the safe concurrency patterns that we've been discussing, there's no need for any synchronization - and indeed there are no synchronization primitives in Pony - Pony applications are lock-free by nature.

No blocking operations

%% In fact, there are no blocking operations at all - so your actors never spend any time waiting around (except for more messages)

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
  
  fun age_diff(other: Person): U8 =>
    if age > other.age
    then age - other.age
    else other.age - age
    end
```

%% Here we have a class, with all of the typical basic features you'd expect of an object-oriented language - our class has some fields (`name` and `age`), as well as some methods (`greeting` and `age_diff`).

%% You'll note that each field has an explicit type - `name` is always a `String`, and `age` is always a `U8`, which is short for "unsigned 8-bit integer".

%% Each method also has a return type - `greeting` returns a `String` and `age_diff` returns a `U8` - like in Ruby, the final expression of the method is implicitly used as a return value - this is true unless the return type is `None`.

%% The `age_diff` method also accepts an argument called `other`, which is of the `Person` type.

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

%% Next, lets look at how references work.

%% Here, we create three references, two `let`s and a `var` - each referencing a unique new Person object.

%% We can reassign the `var` named `c` to be an alias of `a` - it now refers to the same object.

%% We *cannot*, however, reassign the `let` named `b` - a `let` can only be assigned once. This should be a familiar concept to Javascript folks.

----

## Pony Concepts
### Introducing Reference Capabilities

| Safe Concurrency Pattern | Ref. Cap. |
|--------------------------|-----------|
| Share Nothing            | `tag`     |
| Share Immutable State    | `val`     |
| Transfer Isolated State  | `iso`     |

%% Now that we've seen the basic Pony syntax for some familiar concepts, let's look at how Pony represents the concurrency concepts we've been discussing.

%% Pony uses a short keyword called a *reference capability* to represent each of these concepts.

%% Reference capabilities denote various restrictions in how object references may be used. There's.

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

%% Now let's look at the full table of Pony reference capabilities.

%% Each object reference in Pony is marked by a specific reference capability, which dictates what can and cannot be done with that object reference - specifically:

%% whether or not the reference can read or write the objects data,
%% whether other references can read or write the objects data, and
%% whether the reference can be sent in a message to another actor.

%% (Discuss each)

----

## Pony Concepts
### Implicit Reference Capabilities

```pony
class Person
  var name: String = "John Doe"
  var age:  U8     = 0
  
  fun age_diff(other: Person): U8 =>
    if age > other.age
    then age - other.age
    else other.age - age
    end
```

```pony
class ref Person
  var name: String val = "John Doe"
  var age:  U8 val     = 0
  
  fun box age_diff(other: Person ref): U8 val =>
    if age > other.age
    then age - other.age
    else other.age - age
    end
```

%% Let's take a look at where we use reference capabilities.

%% Here is our earlier example class - notice that we didn't use any reference capabilities in our first rendering of it - that's because we were just using the implicit defaults everywhere.

%% Every type has a default reference capability. If you don't specify a reference capability when you declare a reference, it will use the default capability for that type. The `String` and `U8` types happen to be `val` by default, meaning that they're immutable values.  Note that this doesn't mean you can't assign a different value to the `name` field of a `Person` - it just means that the `String` object itself cannot be changed.

%% The `Person` type has a default reference capability of `ref`, indicating a "normal" mutable reference with no particular restrictions. If you wanted to use a different capability, like `iso`, so that it would be sendable, you would have to specify `Person iso` instead of just `Person`.

%% We also see the `box` reference capability in the definition of the `age_diff` method - this doesn't refer to the arguments or return value, but rather to the `Person` object instance that we're operating on - in Ruby, we wouild call it `self` - in Javascript, we would it `this` - in Pony we also call it `this` - when you declare a method but don't specify a reference capability for it, `box` is the assumed default.

%% Remember that the `box` reference capability means that we can only read from it, not write to it - because our view of the `Person` instance is a `box`, this means that we can't change any fields of the `Person` from within the `age_diff` method - this makes sense, because just measuring a `Person` object shouldn't change it - if we wanted to change state from within the method, we'd have to declare it as `fun ref age_diff` instead.

%% When the compiler knows that the `age_diff` method doesn't modify any state, it can make certain performance optimizations based on that guarantee

%% From another perspective, declaring as `fun box age_diff` means that we can call this method on any `Person` that we have read access to, not caring whether we have write access or whether anyone else has read or write access.

%% If we were to declare it as `fun ref age_diff`, we would be prevented from calling that method if we didn't have write access to the `Person`.

%% If we were to declare it as `fun val age_diff`, we would be prevented from calling that method if *anyone else* had write access to the `Person`.

%% If we were to declare it as `fun iso age_diff`, we would be prevented from calling that method if anyone else had *any access* to the `Person`, read *or* write.our access

%% Note that in general, restricting what we can do within the method gives us more freedom in how we can call, and vice versa - this is a common theme with compilers - imposing restrictions actually give you more freedom in other ways.

%% Reference capabilities are all about carefully choosing the restrictions we want so that we have freedom (and concurrency) where it counts

----

## Pony Concepts
### Reference Capabilities Summary

%% Reference capabilities may seem convoluted, but if you spend a little time using them, they become second-nature, and you start to see all of your concurrency problems in these terms

%% These concepts are often implicit in our code anyway when we're writing concurrent applications. Making the ideas explicit in syntax helps us organize our thoughts and prove to ourselves and the compiler that what we're doing is safe
