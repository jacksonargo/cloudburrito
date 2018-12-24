// Code generated by mockery v1.0.0. DO NOT EDIT.

package models

import mock "github.com/stretchr/testify/mock"
import time "time"

// MockPack is an autogenerated mock type for the Pack type
type MockPack struct {
	mock.Mock
}

// Assign provides a mock function with given fields: _a0
func (_m *MockPack) Assign(_a0 Patron) time.Time {
	ret := _m.Called(_a0)

	var r0 time.Time
	if rf, ok := ret.Get(0).(func(Patron) time.Time); ok {
		r0 = rf(_a0)
	} else {
		r0 = ret.Get(0).(time.Time)
	}

	return r0
}

// EnRoute provides a mock function with given fields:
func (_m *MockPack) EnRoute() time.Time {
	ret := _m.Called()

	var r0 time.Time
	if rf, ok := ret.Get(0).(func() time.Time); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(time.Time)
	}

	return r0
}

// Fail provides a mock function with given fields:
func (_m *MockPack) Fail() time.Time {
	ret := _m.Called()

	var r0 time.Time
	if rf, ok := ret.Get(0).(func() time.Time); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(time.Time)
	}

	return r0
}

// ID provides a mock function with given fields:
func (_m *MockPack) ID() ID {
	ret := _m.Called()

	var r0 ID
	if rf, ok := ret.Get(0).(func() ID); ok {
		r0 = rf()
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(ID)
		}
	}

	return r0
}

// IsAssigned provides a mock function with given fields:
func (_m *MockPack) IsAssigned() bool {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// IsEnRoute provides a mock function with given fields:
func (_m *MockPack) IsEnRoute() bool {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// IsFailed provides a mock function with given fields:
func (_m *MockPack) IsFailed() bool {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// IsLost provides a mock function with given fields:
func (_m *MockPack) IsLost() bool {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// IsReceived provides a mock function with given fields:
func (_m *MockPack) IsReceived() bool {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// IsStale provides a mock function with given fields:
func (_m *MockPack) IsStale() bool {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// Latency provides a mock function with given fields:
func (_m *MockPack) Latency() time.Duration {
	ret := _m.Called()

	var r0 time.Duration
	if rf, ok := ret.Get(0).(func() time.Duration); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(time.Duration)
	}

	return r0
}

// Receive provides a mock function with given fields:
func (_m *MockPack) Receive() time.Time {
	ret := _m.Called()

	var r0 time.Time
	if rf, ok := ret.Get(0).(func() time.Time); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(time.Time)
	}

	return r0
}

// String provides a mock function with given fields:
func (_m *MockPack) String() string {
	ret := _m.Called()

	var r0 string
	if rf, ok := ret.Get(0).(func() string); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(string)
	}

	return r0
}

// TimeAlive provides a mock function with given fields:
func (_m *MockPack) TimeAlive() time.Duration {
	ret := _m.Called()

	var r0 time.Duration
	if rf, ok := ret.Get(0).(func() time.Duration); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(time.Duration)
	}

	return r0
}