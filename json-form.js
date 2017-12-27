'use strict';

/**
 * Checks that an element has a non-empty `name` and `value` property.
 * @param  {Element} element  the element to check
 * @return {Bool}             true if the element is an input, false if not
 */
const isValidElement = element => element.name && element.value;

/**
 * A more verbose implementation of `formToJSON()` to explain how it works.
 *
 * NOTE: This function is unused, and is only here for the purpose of explaining how
 * reducing form elements works.
 *
 * @param  {HTMLFormControlsCollection} elements  the form elements
 * @return {Object}                               form data as an object literal
 */
const formToJSON_deconstructed = elements => {

  const reducerFunction = (data, element) => {
    data[element.name] = element.value;
    return data;
  };

  const reducerInitialValue = {};
  const formData = [].reduce.call(elements, reducerFunction, reducerInitialValue);
  
  return formData;
};

/**
 * Retrieves input data from a form and returns it as a JSON object.
 * @param  {HTMLFormControlsCollection} elements  the form elements
 * @return {Object}                               form data as an object literal
 */
const formToJSON = elements => [].reduce.call(elements, (data, element) => {

  // Make sure the element has the required properties and should be added.
  if (isValidElement(element)) {
    data[element.name] = element.value;
  }

  return data;
}, {});

/**
 * A handler function to prevent default submission and run our custom script.
 * @param  {Event} event  the submit event triggered by the user
 * @return {void}
 */
const handleFormSubmit = event => {

  event.preventDefault();

  const form = event.currentTarget;  
  const data = formToJSON(form.elements);
  const json = JSON.stringify(data, null, "  ");

  const headers = new Headers({
      "content-type": "application/json;charset=utf-8"
  });

  fetch(form.action, {
    method: 'post',
    mode: 'same-origin',
    credentials: 'same-origin',
    headers,  
    body: json
  }).catch(console.log);
};

export { handleFormSubmit }
