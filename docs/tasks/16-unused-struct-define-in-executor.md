# Remove unused struct-define in executor symbols function

## Summary

The `symbols` actor method has an unnecessary `struct-define` that
binds fields of `state` without using any of them.

## Affected Code

### `ruckus-core/executor.rkt:149-152`

```racket
(define (symbols st id)
  (struct-define state st)
  (let ([ex (get-execution st id)])
    (values st (unbox (execution-symbols-box ex)))))
```

`struct-define state st` binds `sequence` and `executions` into scope,
but neither is referenced — `get-execution` receives `st` directly.

## Suggested Fix

Remove the unnecessary binding:

```racket
(define (symbols st id)
  (let ([ex (get-execution st id)])
    (values st (unbox (execution-symbols-box ex)))))
```
