type User = {
	firstName: string;
	lastName: string;
	address: Address;
};

interface Address {
	street: string;
	city: string;
	country: string;
}

const user: User = {
	firstName: "John",
	address: {
		city: "New York",
		country: "USA",
	},
};
