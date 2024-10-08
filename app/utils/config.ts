/**
 * Config module
 *
 * Single point of access for the application configuration. Handles validation on required environment variables.
 * The configuration is evaluate eagerly at the first access to the module. The module exposes convenient methods to access such value.
 */

import * as t from "io-ts";
import { readableReport } from "italia-ts-commons/lib/reporters";
import { NonEmptyString } from "italia-ts-commons/lib/strings";

// global app configuration
export type IConfig = t.TypeOf<typeof IConfig>;
export const IConfig = t.interface({
  MAILUP_ALLOWED_GROUPS: t.array(t.string).type,
  MAILUP_ALLOWED_LISTS: t.array(t.string).type,
  MAILUP_CLIENT_ID: NonEmptyString,
  MAILUP_SECRET: NonEmptyString,
  MAILUP_REFRESH_TOKEN: NonEmptyString,
  RECAPTCHA_SECRET: NonEmptyString
});

// No need to re-evaluate this object for each call
const errorOrConfig: t.Validation<IConfig> = IConfig.decode({
  ...process.env
});

/**
 * Read the application configuration and check for invalid values.
 * Configuration is eagerly evalued when the application starts.
 *
 * @returns either the configuration values or a list of validation errors
 */
export function getConfig(): t.Validation<IConfig> {
  return errorOrConfig;
}

/**
 * Read the application configuration and check for invalid values.
 * If the application is not valid, raises an exception.
 *
 * @returns the configuration values
 * @throws validation errors found while parsing the application configuration
 */
export function getConfigOrThrow(): IConfig {
  return errorOrConfig.getOrElseL(errors => {
    throw new Error(`Invalid configuration: ${readableReport(errors)}`);
  });
}
