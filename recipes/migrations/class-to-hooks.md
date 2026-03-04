# React Class Components to Hooks Migration

> Convert React class components to modern functional components with hooks while preserving all behavior, lifecycle logic, and edge cases.

## When to Use

- When modernizing a React codebase that uses class components
- When a class component needs new features that are easier to implement with hooks
- When you want to reduce bundle size (functional components are smaller)
- When preparing for concurrent React features that work better with functional components

## The Prompt

```
You are a React migration expert. Convert the provided React class component(s) to functional components with hooks. The converted component must be behaviorally identical to the original, including all lifecycle timing, error handling, and edge cases.

## CONVERSION RULES

### State
- `this.state = { ... }` -> `useState()` for each independent piece of state
- If multiple state values always change together, keep them in a single `useState` with an object
- If state updates depend on previous state, always use the functional form: `setState(prev => ...)`
- `this.setState` callback (second argument) -> use `useEffect` that depends on the state value

### Lifecycle Methods

| Class Method                  | Hooks Equivalent                                   |
|-------------------------------|---------------------------------------------------|
| `constructor`                 | `useState` initial values + top-level statements   |
| `componentDidMount`           | `useEffect(() => { ... }, [])`                     |
| `componentDidUpdate`          | `useEffect(() => { ... }, [deps])` or `useEffect(() => { ... })` |
| `componentWillUnmount`        | `useEffect(() => { return () => cleanup }, [])`    |
| `shouldComponentUpdate`       | `React.memo()` wrapper with custom comparison      |
| `getDerivedStateFromProps`    | Compute during render (variable assignment) or `useState` + update in render |
| `getSnapshotBeforeUpdate`     | `useRef` + `useLayoutEffect` (rare, flag if needed)|
| `componentDidCatch`           | Keep as class component (error boundaries require classes) OR use a library like react-error-boundary |

### Refs
- `createRef()` -> `useRef()`
- Callback refs -> `useCallback` ref pattern
- String refs (legacy) -> `useRef()`
- `this.myRef.current` -> `myRef.current` (no change in access pattern)

### Instance Variables (non-state, non-ref)
- `this.intervalId`, `this.abortController`, etc. -> `useRef()` (mutable ref that doesn't trigger re-renders)
- These are NOT state because changing them should NOT cause a re-render

### Context
- `static contextType = MyContext` -> `useContext(MyContext)`
- Multiple contexts: nest `useContext` calls (no need for nested Consumer components)

### Event Handlers
- Class methods -> functions defined inside the component or wrapped in `useCallback` if passed as props to child components
- Only use `useCallback` when the function is passed to a memoized child component or used as a `useEffect` dependency. Don't wrap every handler in useCallback

### Performance
- `PureComponent` -> `React.memo(Component)`
- `shouldComponentUpdate(nextProps, nextState)` -> `React.memo(Component, (prevProps, nextProps) => { ... })` (note: return true to SKIP re-render, opposite of shouldComponentUpdate)
- Expensive calculations in render -> `useMemo(() => compute(deps), [deps])`

### Error Boundaries
- Error boundaries CANNOT be converted to functional components (React limitation as of React 18)
- If the component is an error boundary, either keep it as a class or extract the error boundary into a separate class wrapper and convert only the rendering logic to a functional component
- Alternatively, suggest using the `react-error-boundary` library

### IMPORTANT: Preserve These Behaviors
- Preserve the exact same props interface (don't rename or restructure props)
- Preserve forwardRef if the component accepts refs
- Preserve displayName if set
- Preserve default props (convert static defaultProps to default parameter values)
- Preserve the component's position in the render tree (don't wrap in extra divs)
- Preserve all event handler behavior and side effects
- If the class component has methods called by parent via ref, use `useImperativeHandle`

### What NOT to Do
- Do NOT change the component's external API (props, ref interface, context)
- Do NOT combine unrelated state into one useState call
- Do NOT add unnecessary useMemo or useCallback (premature optimization)
- Do NOT change the rendering logic or JSX structure
- Do NOT fix bugs during migration (note them as TODOs instead)
- Do NOT change the file's export pattern (default vs. named)

## OUTPUT FORMAT

Provide:
1. The complete converted functional component
2. A migration notes section listing:
   - Each lifecycle method and its hooks equivalent
   - Any behavioral nuances to verify in testing
   - Any changes that couldn't be made (e.g., error boundaries)
   - Suggested follow-up refactors (but not done in this migration)
```

## Example

### Input

```jsx
import React, { Component, createRef } from 'react';
import { fetchUserData, subscribeToUpdates } from '../api/user';
import { UserContext } from '../contexts/UserContext';
import Spinner from './Spinner';

class UserDashboard extends Component {
  static contextType = UserContext;

  static defaultProps = {
    refreshInterval: 30000,
    showNotifications: true,
  };

  constructor(props) {
    super(props);
    this.state = {
      userData: null,
      loading: true,
      error: null,
      activeTab: 'overview',
    };
    this.scrollRef = createRef();
    this.unsubscribe = null;
  }

  componentDidMount() {
    this.loadUserData();
    if (this.props.showNotifications) {
      this.unsubscribe = subscribeToUpdates(this.context.userId, (update) => {
        this.setState((prev) => ({
          userData: { ...prev.userData, ...update },
        }));
      });
    }
    this.refreshTimer = setInterval(this.loadUserData, this.props.refreshInterval);
  }

  componentDidUpdate(prevProps) {
    if (prevProps.userId !== this.props.userId) {
      this.loadUserData();
    }
  }

  componentWillUnmount() {
    if (this.unsubscribe) this.unsubscribe();
    clearInterval(this.refreshTimer);
  }

  loadUserData = async () => {
    try {
      this.setState({ loading: true, error: null });
      const data = await fetchUserData(this.props.userId);
      this.setState({ userData: data, loading: false });
    } catch (err) {
      this.setState({ error: err.message, loading: false });
    }
  };

  handleTabChange = (tab) => {
    this.setState({ activeTab: tab });
    this.scrollRef.current?.scrollTo(0, 0);
  };

  render() {
    const { userData, loading, error, activeTab } = this.state;
    const { showNotifications } = this.props;

    if (loading && !userData) return <Spinner />;
    if (error) return <div className="error">{error}</div>;

    return (
      <div ref={this.scrollRef} className="dashboard">
        <nav>
          {['overview', 'activity', 'settings'].map((tab) => (
            <button
              key={tab}
              className={tab === activeTab ? 'active' : ''}
              onClick={() => this.handleTabChange(tab)}
            >
              {tab}
            </button>
          ))}
        </nav>
        <main>{/* tab content rendering */}</main>
      </div>
    );
  }
}

export default UserDashboard;
```

### Output

```jsx
import React, { useState, useEffect, useRef, useContext, useCallback } from 'react';
import { fetchUserData, subscribeToUpdates } from '../api/user';
import { UserContext } from '../contexts/UserContext';
import Spinner from './Spinner';

function UserDashboard({
  userId,
  refreshInterval = 30000,
  showNotifications = true,
}) {
  const [userData, setUserData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeTab, setActiveTab] = useState('overview');

  const scrollRef = useRef(null);
  const refreshTimerRef = useRef(null);

  const { userId: contextUserId } = useContext(UserContext);

  const loadUserData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchUserData(userId);
      setUserData(data);
      setLoading(false);
    } catch (err) {
      setError(err.message);
      setLoading(false);
    }
  }, [userId]);

  // componentDidMount + componentWillUnmount: data fetching and refresh timer
  useEffect(() => {
    loadUserData();

    refreshTimerRef.current = setInterval(loadUserData, refreshInterval);

    return () => {
      clearInterval(refreshTimerRef.current);
    };
  }, [loadUserData, refreshInterval]);

  // componentDidMount + componentWillUnmount: real-time subscription
  useEffect(() => {
    if (!showNotifications) return;

    const unsubscribe = subscribeToUpdates(contextUserId, (update) => {
      setUserData((prev) => (prev ? { ...prev, ...update } : prev));
    });

    return () => {
      unsubscribe();
    };
  }, [contextUserId, showNotifications]);

  // componentDidUpdate: reload when userId changes (handled by loadUserData
  // being in the dependency array of the fetch effect)

  const handleTabChange = (tab) => {
    setActiveTab(tab);
    scrollRef.current?.scrollTo(0, 0);
  };

  if (loading && !userData) return <Spinner />;
  if (error) return <div className="error">{error}</div>;

  return (
    <div ref={scrollRef} className="dashboard">
      <nav>
        {['overview', 'activity', 'settings'].map((tab) => (
          <button
            key={tab}
            className={tab === activeTab ? 'active' : ''}
            onClick={() => handleTabChange(tab)}
          >
            {tab}
          </button>
        ))}
      </nav>
      <main>{/* tab content rendering */}</main>
    </div>
  );
}

export default UserDashboard;
```

**Migration Notes:**
- `constructor` -> `useState` for each piece of state, `useRef` for scrollRef and timer
- `componentDidMount` -> Split into two `useEffect` calls: one for data fetching + timer, one for subscription (separation of concerns)
- `componentDidUpdate(prevProps.userId)` -> Handled by `loadUserData` in the `useCallback` dependency on `userId`, which flows into the `useEffect` dependency array
- `componentWillUnmount` -> Cleanup functions in each `useEffect`
- `static contextType` -> `useContext(UserContext)`
- `static defaultProps` -> Default parameter values in function signature
- `this.refreshTimer` (instance variable) -> `useRef` (not state, since changing it shouldn't re-render)
- `loadUserData` wrapped in `useCallback` because it is used as a `useEffect` dependency
- `handleTabChange` is NOT wrapped in `useCallback` because it is not passed to memoized children

## Customization Tips

- **For TypeScript class components**, add: "Convert `Component<Props, State>` generics into typed `useState` calls and a typed props interface. Remove the State interface since state is now managed per-field with useState."
- **For components using HOCs**, add: "If the class component is wrapped in connect(), withRouter(), or similar HOCs, convert to their hook equivalents: useSelector/useDispatch, useNavigate, etc."
- **For components with complex state**, add: "If the component has more than 5 pieces of interrelated state, consider using useReducer instead of multiple useState calls. Define the action types and reducer function."
- **For batch migration**, add: "Process leaf components first (those with no class component children), then work upward. This prevents breaking parent-child ref or callback patterns."

## Tags

`migration` `react` `hooks` `class-components` `modernization` `refactoring`
