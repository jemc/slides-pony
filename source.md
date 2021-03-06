
![Pony](img/horse.png)

# Pony
## An Actor Language For
### Provably Safe Lockless Concurrency

---

## Who Am I?

![jemc](img/jemc.png) ![cb](img/cb.png) ![pony](img/ponylogo-invert.png)

### Joe Eli McIlvain - Citrusbyte - Pony Core

[github.com/jemc](https://github.com/jemc) - [citrusbyte.com](https://citrusbyte.com) - [ponylang.org](https://ponylang.org)

These slides on GitHub: [github.com/jemc/slides-pony](https://github.com/jemc/slides-pony)

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

%% We just don't know, and concurrent code is code that operates under the paradigm of not knowing this.

%% To be clear, each *task* is a linear sequence of operations with a well-defined order, but the timing of the operations in a task *relative* to those in the *other* concurrent tasks is arbitrary and undefined.

----

## Concurrency

### Why do we want it?

%% So, why do we want concurrency?

%% Well, it turns out that just prepping our application for concurrency isn't enough to get any *direct* benefits, though as we discussed, it allows our code to be run in *parallel*, and *that* in turn can give us some very important benefits:

Concurrency alone isn't enough, but...

Running our code in *parallel* can give us:

* scalability %% We want to be able to add processors to get proportionally more throughput - that's scalability.

* efficiency %% We don't want to have any idle processors, as that would be inefficient - we want to put all of our processors to work for efficiency.

----

## Concurrency

### Why do we fear it?

%% So, why do we fear concurrency? - what's the problem?

Non-determinism in the order of events

%% Essentially, with concurrency, we want to be able to write applications where we don't know the order in which everything is happening, but we can be sure that the final result is always correct.

%% This may sound a bit difficult, because it is. Arbitrary relative timings are a type of *nondeterminism*, and we want our overall application to be *deterministic*.

%% Now, we can easily allow order-nondeterminism where it doesn't matter. For example, if I ask you to go get groceries, clean the bathroom, and finish painting the shed, I probably don't care what order you do those things in, as long as they each get done.

%% However, if I ask you to go get groceries, deposit the paycheck, and pay the rent, the order in which you do these things might matter a great deal, depending on how much money is in our checking account.

Can lead to subtle bugs

%% Depending on how we structure our code and our concepts, the order-nondeterminism of concurrency can lead to subtle bugs that are difficult to reason about, reproduce, and test for.

%% One really common example is a data race, where one or more tasks access the same data in an undefined order, where some of those order possibilities lead to incorrect behavior.

----

## Concurrency

### So how do we stay sane?

%% Given that we want concurrency, but dealing with concurrency can bring about these problems, how do we go about creating concurrent applications that we can be confident about?

Embrace a structured approach

%% Well, we need to embrace a structured approach to concurrency, where that structure brings some sanity and reason back to the jumble of nondeterminism that we'd otherwise be faced with.

%% In other words, we want to impose some strategic limits on ourselves and our code in order to limit the possible states of the resulting concurrent system.

%% So let's take a look at some of the structured approaches and conventions that we see out there...

---

## Synchronization

> Wherever my tasks share state with eachother, I can synchronize access to that state appropriately to avoid concurrency bugs.

----

## Synchronization

### How does it help?

%% So, how does it help?

Use locks to restrict the relative order of events

%% Using synchronization primitives like locks allows us to impose *restrictions* on the relative order of *specific groups* of operations within concurrent tasks.

Blocks the task instead of violating the restriction

%% Effectively, these primitives force the tasks to *wait* (or *block*) for availability where they would otherwise plunge ahead and violate the given restrictions.

%% Typically, a lock is conceptualized as something that you *acquire* before you do some work on some shared state, then *release* when you're done. If you, as a task, are ready to do that work, and some other task is "holding" the lock, you wait around, idle - you can't do your work until the other task releases the lock to you. And if there are lots of other tasks of waiting for the same lock, you may be waiting quite a while before you get your turn.

%% But, if planned appropriately and effectively, these restrictions *can* prevent the kinds of concurrency bugs we highlighted.

%% However, let's take another look at what synchronization is actually doing to our applications.

----

## Synchronization

### Reduces Concurrency

%% Synchronization *reduces* concurrency

Synchronized operations become non-concurrent

%% We've said that synchronization primitives allow the programmer to impose *restrictions* on the order of specific groups of operations, and we've also said that *concurrency* is the paradigm of not knowing the order of operations.

%% So, we see that synchronization works by allowing us to selectively *prevent concurrency* of certain operations.

%% As an extreme example, note that if we use a common lock to synchronize the entire block of code for each concurrent task in a program - so they're all using the same single global lock, and the entire tasks are synchronized - effectively, at this point there is no concurrency left at all - the lock will force our tasks to be run sequentially instead of concurrently.

%% Now, that *was* an extreme and contrived example, but we can see that in less extreme cases, it behaves the same way - the more synchronization we introduce in our tasks the more they end up waiting around, and the more we *reduce the degree of effective concurrency*

More synchronization => less concurrency

%% Stepping back a bit, yes, that's obviously what we *want* to do - to impose a few specific restrictions on the order of events so we can ensure correctness, but leaving the rest of the order up to random chance - however, using synchronization reduces concurrency in *such a way that* it makes *waiting for access* to things a central part of our approach, and that comes up against our earlier goal of efficiency - we want to keep things moving as much as possible - we want to avoid idle tasks when there is still more work to be done.

More synchronization => more waiting

%% So, this puts us in the unfortunate situation where the more we use synchronization the more we will lose the benefits concurrency gives us - synchronization may be fine in small doses, but if we lean on it as a crutch and use it as our go-to concurrency safety mechanism, our application performance may suffer.

%% A familiar example of over-synchronization is the Global Interpreter Lock (or GIL) found in the reference implementation of Ruby, in which *almost* all of the operations of the interpreter are synchronized by a single global lock, which severely reduces the actual concurrency that is possible using Ruby Threads - it's worth noting that the competing Ruby implementations, Rubinius and JRuby, improve on this strategy by using many fine-grained locks instead of one single global lock, so that some operations may be concurrent with some others - because they're not contending with the same lock.

----

## Synchronization

### is Error Prone

Lose as little concurrency as possible by being precise

More precise synchronization => more concurrency

%% So, to avoid losing too much concurrency to over-synchronization, we want to use synchronization primitives in a precise, detail-oriented way - synchronizing as little as is necessary to be safe - if we go back to our earlier example of Ruby's Global Interpreter Lock and the work in Rubinius and JRuby to separate this locking into more fine-grained locks, this is basically what we're talking about - more precision helps us to keep more opportunities for concurrency while still remaining exclusive where it counts.

%% However, in many cases this work is non-trivial, and even when done, understanding and maintaining it often entails a lot of additional cognitive complexity - thinking about all these locks, the circumstances under which you need to acquire each one, and the circumstances under which the total "interlocking" system might *deadlock* or otherwise behave badly - it gets to be quite a lot for a human (or an automated tool) to reason about.

More precise synchronization => more cognitive complexity

%% In essence, the more precisely we use synchronization (the finer-grained locks we use), the more difficult it becomes to reason about possible outcomes and the more likely we are to cause or fail to prevent concurrency bugs.

%% Regrettably, using synchronization with concurrency creates a situation where the more performance-optimal our code becomes, the more difficult it becomes to understand and maintain.

%% This is a terrible tradeoff, and grappling with it in this way is one of the main reasons why we're afraid of concurrency.

%% So let's take a look at to another approach:

---

## Share Nothing

> If my tasks share no state with eachother, then safe concurrency is trivial.

----

## Share Nothing

### Why is it safe?

%% So why is it safe?

We get bugs when we share state,

So let's not share any state.

%% Well, the concurrency bugs we highlighted were all related to the interdependence of concurrent tasks - put another way, we get problems when we share state between tasks.

%% So, if we want to avoid the problems associated with access to shared state, one trivial remedy is to avoid shared state altogether.

%% And indeed, when you can pull it off, this works *beautifully* - it scales perfectly because there is no relationship at all between the tasks, so there's no possibility of a bottleneck as you scale.

* no interdependence

* no communication

%% If our concurrent tasks are truly independent from one another, the nondeterminism of relative timings doesn't matter - that is, every possible order of events is correct behavior, because the tasks don't care about eachother at all.

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

%% With some consideration, we see it's not quite necessary to prohibit all sharing - rather it's sufficient to make sure that anything we do share is immutable - that is, guaranteed to never change.

%% If the data in the shared state is guaranteed to never change, then any task can read from it at any time and always see the same data.

%% There's no need to synchronize because a read operation will have never have any influence over the outcome of any other read operations.

* immutable data structures

* frozen objects

%% These nice properties - as well as others - make immutable data structures a popular choice for shared data, and part of the central paradigm for many modern functional programming languages - as long as your data structures are immutable, there are no data races to worry about.

----

## Share Immutable State

### Advantages

* always safe
* easy to reason about
* provides a way to share global data
%% giving in to the restriction that it can't be changed

----

## Share Immutable State

### Disadvantages

* can't migrate between distinct tasks without copying data
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

%% Let's talk about what we mean when we say isolated - isolated state is only accessible from one task at a time, so it is not really concurrently *shared*.

%% When tasks are implemented as threads, this is sometimes called *thread-ownership* - the state object is held exclusively by a single thread, its owner - and no other thread touch it.

%% This is clearly safe, but without sharing, it doesn't solve the original problem.

%% We can't share isolated state among multiple tasks at once, but we *can* share isolated state *across time* by securely transferring it from one task to another - this is sometimes called *message passing* or *transferring* thread ownership.

* "thread ownership"

* "message passing"

%% When I say securely transferring, I mean this - if we can guarantee that the original task doesn't hold on to any dangling references to the transferred state object, then it is still isolated when it reaches the next task - but if even a single reference is retained in the original task - sometimes called a *leaked* reference - all safety goes out the window, because both tasks have access to the same mutable state object at the same time.

%% So this method usually requires strict discipline to avoid leaking references, *or* you need language that supports enforcing that no references are leaked, taking the need for that discipline off your shoulders.

----

## Transfer Isolated State

### Advantages

* easy to reason about
* no mutability restrictions
* compatible with zero-copy optimizations
%% for example, I can accept a byte buffer from a network socket, make some modifications to it, and pass it to the next task, which may also make some modifications, and keep passing it til the end of my processing chain, still mutable, all without copying the data in the buffer (which is nice to avoid, because it can be a real performance killer if the byte buffer is large)

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

%% However, we do want to avoid *traditional* synchronization primitives because of that performance vs reasoning tradeoff we discussed earlier.

%% We'll still have some patterns that are *analogous* to synchronization, in that they'll provide a way to write transactions that have exclusive access to some state, but we're going to construct these patterns with careful intent to avoid making *waiting* a central part of our solution.

----

## So what do we want?

%% So, what do we want?

Easy to use the safe patterns

%% We want to use tools and conventions that make these safe patterns easy to use - programmers are lazy, so we have to make it easier to do the right thing or we'll mostly choose to do the wrong thing. Some people call this "falling into the pit of success".

Verify safety by verifying the patterns

%% In fact, let's take it a step further and say that we never want to ship an application that isn't concurrency safe. If we verify and *enforce* the safe patterns, then we can write highly concurrent applications while remaining fully confident in their safety.

Clear and explicit - no guesswork

%% Since we're mixing and matching the safe concurrency patterns, we also want to make it clear to our tools and to ourselves which patterns we are using for any given part of our code. For example, no human or tool that's reading our code should ever have to guess whether a given state object is intended to be *immutable* or *isolated*.

%% Explicit clarity of intent will keep our applications easy to reason about as their behaviour becomes more complex.

Clean, consistent syntax and rules

%% Furthermore, the way we show our intent should be ubiquitous and uniform, with a clean, consistent syntax, and simple rules for understanding what that syntax means.

---

## Enter Pony
### A Language for Provably Safe
### Lockless Concurrency

Pony website: [ponylang.org](https://ponylang.org)

Pony on GitHub: [github.com/ponylang/ponyc](https://github.com/ponylang/ponyc)

%% Pony is a programming language that was built with exactly these goals in mind. It was built to empower you to have an explicit and elevated dialogue with the compiler about the concurrency patterns in your program, so that you and the compiler can work *together* to prove that the way you're using concurrency is safe. All so that you *and* your application don't have to worry about it later while the program is running - your program gets to plunge ahead without waiting for locks or checking for safety, and you get to sleep through the night while your pager stays silent.

----

## Enter Pony
### A Static, Compiled Language

Static analysis enforces concurrency patterns

Understands your application without running it

%% So, as I mentioned, Pony is a static, compiled language. The compiler is the tool that statically analyzes and enforces the safe concurrency patterns we've been talking about - in case you're not familiar, "static" just means that it doesn't have to run your code to understand it - the compiler analyzes the program ahead of time.

Concurrency safety without cost of runtime checks

%% If Pony were a dynamic language (as opposed to static), it wouldn't start to understand your code until it was running - This effectively means it would need to run your code surrounded by a bunch of runtime checks to ensure concurrency safety at every step of the way, effectively slowing down your code as well as making you add a bunch of guard code to "rescue" concurrency violation errors if they do happen, because you wouldn't know ahead of time if those violations were there or not.

%% Doing this analysis statically instead allows your application to only spend its time doing only "business logic", and not checking whether its safe to read from or write to any given reference - it can safely plunge ahead with the assumption that the safety of whatever its about to do was verified at compile time.

High performance

%% In terms of performance, Pony code should be comparable to code written in C or C++ since it compiles down to a minimal LLVM representation that looks a lot like what you might see produced by the `clang` compiler (which compiles C and C++ code using LLVM).

----

## Enter Pony
### A Strongly-Typed Language

%% Pony is a strongly-typed language - verifying type safety is part of the static analysis that the compiler does. All references in your program must have an explicit (or inferred) type, and the types in your program have well-defined subtyping relationships to eachother.

%% Now, some of you may groan a little bit here, and I definitely groaned about this at one time, I was totally comfortable writing robust code in a "type-less" language like Ruby or Python, and I had often argued before I came to Pony that *strongly typed* languages usually create more hassle for the programmer than they solve real problems. Now, after getting hooked on Pony, I've changed my views on that quite a bit, but at the time I came to Pony I was quite skeptical of the benefits of strong typing.

And concurrency is part of the type system!

%% However, in Pony, the concurrency patterns we've been talking about are *part of the type system*. This is a big deal because while it may be pretty easy for you to intuitively understand and reason about what *types* of objects you're dealing with in each part of a well-organized application, it can be much harder to understand and reason about how those objects might be accessed concurrently, and having those assumptions be implicit means that you or others will inevitably get confused at some point as to what's going on and who can access what and whether waiting for a lock is needed.

%% This is what ultimately sold me on embracing Pony's strongly-typed approach - the safe concurrency pattern enforcement that forms the core value proposition of the language *couldn't exist* without the compiler having the information it gets from strong typing - in Pony, the concurrency access pattern for every reference is *part of its type*.

----

## Enter Pony
### An Actor Language

%% Pony is an actor language.

%% This means that instead of expressing concurrency in terms of explicit threads, fibers, processes, or co-routines, we use a higher-level abstraction called actors.

Pass messages, trigger behaviours

%% In short, actors are objects which don't provide synchronous access to any of their internal state - that is, you cannot read an actor's fields, and you cannot call an actor method and expect a return value - instead you pass it an asynchronous message that triggers a corresponding *behaviour* when the message is received - but you don't know or care when that is, and you don't spend any time waiting around for a result.

Messages have causal order, not sequential order

%% Essentially, when we think about actors, we shift our paradigm from thinking about sequences of actions and instead think our program in terms of causes and effects - forcing ourselves into this paradigm shift in turn makes it easy for the runtime scheduler to execute tasks in parallel - more broadly, any task can be scheduled to execute at any time, *provided that* the effect does not precede the cause - this is the rule the Pony runtime is based on - we call this "causal message order".

%% I don't want to get too deep into causal message order here because our time is limited, but suffice to say that Pony's causal message order actually provides a stronger order guarantee than other actor languages like Erlang - messages originating from the same source that are sent to the same destination and have a well-defined causal order are guaranteed to arrive at their destination in the same order. So, if my logger is an actor, and writing to the log is asynchronous, I can fire off multiple log messages originating from the same actor, and know that they won't arrive out of order (though they may be interleaved with messages originating from other actors). This turns out to also be a *really* useful guarantee for user applications, eliminating a whole class of common concurrency mistakes.

Per-actor garbage collection (no stop-the-world step)

%% But it isn't just a nice feature that the creators of Pony decided to include to make programmers' lives easier - this type of causal message ordering is actually critical to the way the Pony garbage collector works - Pony has a per-actor garbage collector with *no* "stop the world" step - it uses message passing to track references across actor boundaries and the garbage collector protocol hinges on the causality of message order - if you're interested in reading more about how the garbage collector message protocol works,  there's an academic paper about it you can find on the Pony website.

Scheduled by the runtime (work-stealing algorithm)

%% So, we give actor declarations to the Pony compiler, defining their *behavior* for receiving each kind of message they can handle - and then, in the Pony runtime - the execution of the program is just the unfolding of these messages over time from initial conditions, and from external input. The runtime takes care of scheduling execution in an efficient way (using a "work stealing" algorithm, which also has an academic paper you can read about it) over a fixed number of system threads (by default, equal to the number of cores on your machine), so you never have to worry about spinning up your own threads, or whether you've spun up too many, or anything like that.

No synchronization primitives (lockless)

%% So, coming back to locks - because our actors follow the safe concurrency patterns that we've been discussing, there's no need for any synchronization primitives in Pony - Pony applications are lockless by nature.

%% In a way, the actor is *sort of* a synchronization primitives in that it has exclusive to its own state. However, an actor only accepts asynchronous messages to cause reads or writes to that state, so we've set up our paradigm to promote access *without waiting*.

No blocking operations

%% In fact, in Pony, there are no blocking operations at all - so your actors are never waiting around within a behaviour, unable to receive new messages.

----

## Pony Paradigms
### No Blocking!

Blocking is an anti-pattern

%% As I mentioned in the last slide, blocking in Pony is an anti-pattern. In fact, it's not even possible unless you're using *FFI* to call some native function that might block.

%% Some other actor-oriented languages include a *blocking receive* feature - that is, they have a way to *wait* for a specific response from another actor (or perhaps, a timeout if this response doesn't come within some expected period of time) - Pony doesn't have this, but it's often requested by users coming from other languages - so what gives?

If we allowed blocking it would either:

* make our actor go idle when there is still more work for it to do

* make our actor behaviours non-atomic (and accumulate memory)

%% Well, such a feature is usually implemented in one of two ways - the most straightforward way is to just let the actor block, preventing it from handling any more messages while it's tied up and waiting for that *one* special message (which again, may never arrive or may take arbitrarily long to arrive) - this means your actor may spend a lot of time idle when in fact there are more messages for it and more work to do - this makes our actors start to look a lot like traditional synchronization primitives, always waiting around, which is what we were *trying* to get rid of with this system.

%% So, this obviously isn't ideal, and there's a slightly more clever way to do this - while we wait for this actor to receive that *one* special message (and then take some arbitrary followup action based on the result), we *allow* that actor to handle *other* incoming messages as well, each according to their appropriate behavior - essentially, this means we capture a bit of state that holds the info about what message we're waiting for and what we're going to do when we get it, and then every time a message comes in we compare it to that list of special messages that we're waiting for and see if we can find a match - if we do, we can finish the corresponding followup action and clear out that bit of state - otherwise, the message is one that we have a defined behaviour for, and we just execute that behavior.

%% Now, this has a couple of problems - as you might have guessed, in a highly active system, those *tiny* little bits of state can quickly add up to an arbitrarily big chunk of memory - now, we could put some kind of a limit on this memory, but that means when we reach that limit, we're back to simple waiting again, just like before - the *other* problem is that our actor behaviours are no longer atomic - that is, actor behaviours in Pony current act like *atomic transactions* over the actor's internal state - we have some current state, the message comes in, we execute the corresponding behaviour *in full*, and now that state might look a little bit different (if the behaviour involved changing some of the fields) - if behaviours were not atomic it would mean that at the start of a behaviour, you could check the value of some internal actor field, decide what to do based on that value, call a method that somewhere deep down in its stack chooses to spend some time blocking, then the internal field that you checked before and made that decision about now has an *undefined value* - that is, since you called a blocking method and the actor had a chance to handle other messages, that field may have been changed by those messages - in a world where methods can block and actors keep right on running, you can't call confidently call a method without worrying about whether the rug is going to be pulled out from under you.

%% And, in fact, I attended a talk yesterday by Christoph Jentzsch where he talked about the Ethereum DAO hack last year that lost 50 million dollars from the project when a hacker exploited a re-entrancy bug in their Ethereum smart contract that was made possible by exactly this kind of problem. This kind of bug can be really subtle, and can sneak past some really smart people to cause a lot of trouble.

%% To make our programs easy to reason about, we reject both of these solutions, and we choose to never be idle and always be atomic - and if we ever *do* need to store some state to mark that we are waiting for some special message, we have to do it in explicit application logic - keep that state in a field of the actor, and make it obvious what happens while we wait - the ramifications of waiting in a concurrent program can be severe, and if we ever are waiting for something, we *want* those ramifications to be in our face, staring us down and challenging us to find a different pattern, or at least acknowledge the engineering tradeoffs of the pattern we've chosen.

We choose never-idle, always atomic.

%% This brings up another critical point about concurrent programming - any time you try to hide the asynchronous nature of it - to make the asynchronous appear synchronous - you disguise the truth and prevent the critical thinking required to make good decisions - it's like going through a store and tearing off all the price tags, to the point that you can no longer tell which items are costly and which ones are cheap - we want simplicity, but we don't want to get it by just sweeping the complexity under the rug - we want to distill the essence of the problem and bring it to the surface, where we can make smart choices about how to solve it - and that's what we try to do with concurrent programming in Pony - we don't make the costly appear cheap, we don't make the risky appear safe, and we *don't* make the asynchronous appear synchronous.

We choose to never make the asynchronous appear synchronous.

---

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

%% So, let's finally take a look at some basic syntax for the language.

%% Here we have a class, defined in a way you should find familiar from other object-oriented languages. Now, if you're a die-hard functional programming advocate and the fact that I just said "object" has you looking for the door, just try to keep an open mind and disassociate from the baggage you typically associate with classes and objects - Pony mixes concepts from both object-oriented programming and functional programming in a powerful and practical way, and this is made possible by its unique type system. We'll describe that system in detail in a few slides, so please stick with me.

%% So our class is called `Person`, and it has some fields (`name` and `age`), as well as some functions (`greeting` and `age_diff`).

%% You'll note that each field has an explicit type - `name` is a `String`, and `age` is a `U8`, which is short for "unsigned 8-bit integer".

%% Each method also has a return type - `greeting` returns a `String` and `age_diff` returns a `U8` - like in some other languages, the final expression of the method is implicitly used as the return value - and also note that branching expressions (like the `if`/`then`/`else` block in `age_diff`) also have a value - it's whatever the value of the final expression in the executed branch is - sometimes methods conceptually have no return value, and those can be said to return the type called `None`, which will be added implicitly to the end of the function if you don't given an explicit return type.

%% You'll see that the `age_diff` method also accepts an argument called `that`, which is of the `Person` type - because the keyword `this` is used to refer to the current receiver, just like in C++, `that` is a common Pony idiom for referring to another object of the same type.

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

%% Here, we create three references, two `let` references and one `var` reference - each referencing a unique new `Person` object - we can just say `Person` here in the code, because referring to a type where a value is expected will implicitly call the default constructor.

%% On the fourth line, we can reassign the `var` reference named `c` to be an alias of `a` - we essentially throw away that third `Person` object, and now both `a` and `c` refer to the same `Person`.

%% We *cannot*, however, on the fifth line, reassign the `let` reference named `b` - a `let` can only be assigned once. This should be a familiar concept to Javascript folks.

----

## Pony Concepts
### Introducing Reference Capabilities

| Safe Concurrency Pattern | Ref. Cap. |
|--------------------------|-----------|
| Share Nothing            | `tag`     |
| Share Immutable State    | `val`     |
| Transfer Isolated State  | `iso`     |

%% Now that we've seen the basic Pony syntax for some *familiar* concepts, let's look at Pony's novel way of representing the concurrency patterns we've been discussing.

%% Pony uses a short keyword called a *reference capability* to represent each of these patterns.

%% Reference capabilities denote various restrictions on how object references may be used. There's the "Share Nothing" pattern, represented as `tag`, the "Share Immutable State" pattern, represented as `val`, and the "Transfer Isolated State" pattern, represented as `iso`.

%% The reference capability is *part of the type* of a reference. It also respects the paradigm of capability security in that the read and write restrictions associated with the reference capability of a type can be attenuated to a lower capability, but never escalated to a higher capability. The compiler enforces this as part of the rules of the type system.

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

%% Now let's look at the full table of Pony reference capabilities - there's six in all.

%% Each object reference in Pony is marked by a specific reference capability - one of these six keywords, which dictates what can and cannot be done with that object reference - specifically, as marked in the third, fourth, and fifth columns:

%% whether or not *this* reference can read or write the object's data,
%% whether *other* references can read or write the object's data,
%% and whether the reference can be sent in a message to another actor (sendable).

%% A reference capability can only be sent to another actor if doing so is guaranteed to be safe. This guarantee is the direct result of whether the other constraints are strict enough to constitute one of the three safe concurrency patterns that we discussed. The cardinal rule being enforced here is, "If I can read the data, no other actor can write to it, and vice versa".

%% So let's take a quick look at each reference capability and what it means.

%% `ref` is a mutable reference - the kind of reference you'd find as your only option in most object-oriented languages - another way to look at it is that has no access constraints at all.  For this reason, it is not safely sendable to another actor.

%% `val` is an immutable reference - the kind of reference you'd find as your only option in most functional programming languages - it is read-only, *and* it is guaranteed that *no other references exist* that can write to the same object - it's only readable to *you*, and it's only readable to everyone else - thus, it is guaranteed to never change once it's become a `val`.  This makes it sendable, as it is safe to share concurrently.

%% `box` is a read-only reference - however, it is not considered strongly immutable because there *may* be *other references* that can write to the object -  so even though *you* can't change the object with your reference, it's possible it could be changed using another reference somewhere else - or it could just so happen that it *is* actually immutable globally, but you just have a `box`, and you don't have any way of knowing what's happening anywhere else.  This means it is not safe to share concurrently and so it's not sendable.

%% `iso` is an isolated reference - it is read/write-unique, meaning this reference can access the object (read and write), but *no other references exist* anywhere that can access the object at all.  Because only one actor can hold an isolated reference to an object at any given time, no concurrent access is possible, so it is safe to mutate it.  It is sendable, but note that an actor must *give up* its isolated reference before it can be sent to another actor - we call this "consuming" the reference.  In fact, because of the uniqueness constraint, you can't alias an isolated reference at all without *downgrading* it to a *different* reference capability without the uniqueness constraint.

%% `trn` is similar to an isolated reference, but it is only write-unique instead of read/write-unique, meaning that other references to the object *can exist*, but none of them can *write* to the object.  It is *not* sendable, because it is still mutable and thus cannot be shared.  `trn` is short for *transitional*, because it is most often used as a way to temporarily mutate an object for initialization purposes before converting it to an immutable `val` reference.  You can convert a `trn` to a `val` by consuming the `trn` reference, because it was the only reference one that could write to the object.  By giving up the one reference that can mutate the object, it can become immutable.

%% `tag` is an opaque reference - it allows neither reading from nor writing any of the underlying object's fields.  This may not seem very useful at first, but `tag` is actually the capability used to refer to other actors in Pony.  This makes sense, because you shouldn't be able read or write the actor's fields from outside the actor.  However, the `tag` reference does have the address (or *identity*) of the object, so you can still use a `tag` reference to do identity comparisons for objects, and you can still use it to send asynchronous *messages* to actors - just having the address of the actor is enough to be able to send it messages - and that's exactly what a `tag` reference is - an *address* without *access*.

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

%% Let's take a look at where we use reference capabilities.

%% Here is our earlier example class - notice that we didn't use any reference capabilities in our first rendering of it - that's because we were just using the implicit defaults everywhere. The second rendering here shows those implicit defaults expanded for us to take a look at.

%% Every type has a default reference capability. If you don't specify a reference capability when you declare a reference, it will use the default capability for that type. So, `String` and `U8` expand to `String val` and `U8 val`, because when those types were declared in the standard library, they were declared having `val` as their default capability. This means that if you ever want to use a reference to a mutable string, you have to declare it as `String ref` - otherwise you'll get the default of `String val`.

%% The `Person` type declaration expands to `class ref Person`, meaning that anywhere we see the `Person` type it will expand to `Person ref`. If we were building this class as an immutable data structure, we could have declared it as `class val Person` (and implemented it a bit differently).

%% We also see the `box` reference capability in the definition of the `age_diff` method - `fun box age_diff` - this doesn't refer to the arguments or return value, but rather to the `Person` object instance that we're operating on - known in Pony as `this`, known in some other languages as `self` - this is the object reference that's used accessing fields and methods of the  object - so, in this case, the `this` reference would have the type `Person box`. When you declare a method but don't specify a reference capability for it, `box` is the assumed default.

%% Remember that the `box` reference capability means that we can only read from it, not write to it - because our view of the `Person` instance is a `box`, this means that we can't change any fields of the `Person` from within the `age_diff` method (if we do, the compiler will politely inform us of our folly) - this makes sense, because just measuring a `Person` object shouldn't change it - if we wanted to change state from within the method, we'd have to declare it as `fun ref` instead. This is really a nice way of explicitly controlling which methods are allowed to have side effects that alter state of the current object.

%% An astute viewer might notice that we're also not modifying the *other* `Person` in the `age_diff` method either, so we can actually change that parameter signature to accept a `Person box` for `that` instead of a `Person ref`.

%% From another perspective, declaring as `fun box age_diff` means that we can call this method on any `Person` that we have read access to, not caring whether we have write access or whether anyone else has read or write access.

%% If we were to declare it as `fun ref`, we would be prevented from calling that method if we didn't have write access.

%% If we were to declare it as `fun val`, we would be prevented from calling that method if *anyone else* had write access.

%% If we were to declare it as `fun iso`, we would be prevented from calling that method if anyone else had *any access*.

%% Note that in general, restricting what we can do within the method gives us more freedom in how we can call, and vice versa - this is a common theme with compilers - imposing restrictions actually give you more freedom in other ways.

%% Sean Grove gave an excellent talk about this yesterday, so if you missed it, check out the video when it goes up - the summary is that imposing *the right* restrictions on yourself is what can really set you free.

%% Reference capabilities in Pony are all about carefully choosing and communicating the restrictions we want so that we have freedom (and concurrency) where it counts. We can mix and match concurrency patterns to adopt the right restrictions for the right part of our application, but we have to be intentional about it, and we have to collaborate with the compiler to make sure that mixture is provably safe.

----

## Pony Concepts
### Reference Capabilities Summary

There's a learning curve, but it's worth it!

%% Reference capabilities may seem convoluted at first, but if you spend a little time using them, they become second-nature, and you start to see all of your concurrency problems in these terms.

Ref caps bring explicit structure to lockless concurrency

%% These concepts are implicit in our code anyway when we're writing concurrent applications. Making the ideas explicit in syntax helps us organize our thoughts and prove to ourselves and the compiler that what we're doing is safe.

Ref caps have no runtime cost!

%% One of the really powerful benefits of how reference capabilities are implemented in Pony is that they have no runtime cost - there are no safety checks executed in your running application, because it's all proven safe at compile-time - in fact, reference capabilities don't exist at all at runtime - they are compile-time constraints that fall away in the final compiled code. This is sometimes called a "zero-cost abstraction".

%% The other runtime cost you avoid is the cost of synchronization - again, Pony is lockless - so every time your code is accessing data, it doesn't ever have to wait to acquire a lock - the access is already proven to be safe. This means you're only spending those precious CPU cycles doing the real work of the application.

We've only introduced the basics here

%% So, we've talked a lot about the motivation for reference capabilities in Pony, and we've covered the basics of how they work, but we've only just scratched the surface here. My goal with this talk was to introduce the unique paradigm that Pony brings the table, give you a solid understanding of the basis and motivation for it and hopefully pique your curiosity to go out and learn more with our tutorial and other online content. Even if you don't think you'll want to use Pony on any signficant projects, I'd still highly recommend learning more - if you take the time to really wrap your head around reference capabilities, it's one of those things that will change the way you think about concurrent data safety in every other programming language you work with.

---

%% So, if I've succeeded in piquing your curiosity, or if you have any other questions for me, *please* come up and say hello after the talk. I'd also be more than happy to meet up tonight with anyone who is interested in doing a deep dive into any of the concepts and details I didn't have time to cover today, show off some interesting code samples, chat about how Pony might be applicable to a problem domain you're interested in, or anything of the sort. Come find me - we can make some plans to meet up - I love talking to people about Pony, so don't be a stranger.

%% Thanks, everyone.

![Pony](img/horse.png)

Pony website: [ponylang.org](https://www.ponylang.org)

Pony on GitHub: [github.com/ponylang/ponyc](https://github.com/ponylang/ponyc)

These slides on GitHub: [github.com/jemc/slides-pony](https://github.com/jemc/slides-pony)

---
