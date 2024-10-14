export class CurrenciesService {
  get(id) {
    return fetch(`/currencies/${id}.json`).then((response) => response.json());
  }
}
