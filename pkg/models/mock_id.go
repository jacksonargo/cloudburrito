// Code generated by mockery v1.0.0. DO NOT EDIT.

package models

import mock "github.com/stretchr/testify/mock"

// MockID is an autogenerated mock type for the ID type
type MockID struct {
	mock.Mock
}

// ID provides a mock function with given fields:
func (_m *MockID) ID() string {
	ret := _m.Called()

	var r0 string
	if rf, ok := ret.Get(0).(func() string); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(string)
	}

	return r0
}

// String provides a mock function with given fields:
func (_m *MockID) String() string {
	ret := _m.Called()

	var r0 string
	if rf, ok := ret.Get(0).(func() string); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(string)
	}

	return r0
}